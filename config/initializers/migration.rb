require 'active_record/connection_adapters/abstract/schema_statements'
require 'active_record/connection_adapters/abstract_mysql_adapter'

module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
      def add_index(table_name, column_name, options = {})
        index_name, index_type, index_columns, index_comment = add_index_options(table_name, column_name, options)
        sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{index_columns})"
        sql << " COMMENT '#{index_comment}'" unless index_comment.empty?
        execute sql
      end

      protected
        def add_index_options(table_name, column_name, options = {})
          column_names = Array.wrap(column_name)
          index_name   = index_name(table_name, :column => column_names)

          if Hash === options # legacy support, since this param was a string
            index_type = options[:unique] ? "UNIQUE" : ""
            index_type = "FULLTEXT" if options[:fulltext]
            index_name = options[:name].to_s if options.key?(:name)
          else
            index_type = options
          end

          if index_name.length > index_name_length
            raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters"
          end
          if index_name_exists?(table_name, index_name, false)
            raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
          end
          index_columns = quoted_columns_for_index(column_names, options).join(", ")
          index_comment = quote_string(options[:comment].to_s)

          [index_name, index_type, index_columns, index_comment]
        end
    end

    class AbstractMysqlAdapter < AbstractAdapter
      class IndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :fulltext, :index_comment) #:nodoc:
      end

      # Returns an array of indexes for the given table.
      def indexes(table_name, name = nil) #:nodoc:
        indexes = []
        current_index = nil
        execute_and_free("SHOW KEYS FROM #{quote_table_name(table_name)}", 'SCHEMA') do |result|
          each_hash(result) do |row|
            if current_index != row[:Key_name]
              next if row[:Key_name] == 'PRIMARY' # skip the primary key
              current_index = row[:Key_name]
              indexes << IndexDefinition.new(row[:Table], row[:Key_name], row[:Non_unique].to_i == 0, [], [], nil, nil, row[:Index_type].upcase == 'FULLTEXT', row[:Index_comment])
            end

            indexes.last.columns << row[:Column_name]
            indexes.last.lengths << row[:Sub_part]
          end
        end

        indexes
      end

      def engine(table)
        schema_name = quote(ActiveRecord::Base.configurations[Rails.env]['database'])
        table_name = quote(table)
        sql = "SELECT engine FROM information_schema.tables WHERE table_schema = #{schema_name} AND table_name = #{table_name}"
        execute(sql).first[0]
      end
    end
  end

  class SchemaDumper
    private
      def table(table, stream)
        columns = @connection.columns(table)
        begin
          tbl = StringIO.new

          # first dump primary key column
          if @connection.respond_to?(:pk_and_sequence_for)
            pk, _ = @connection.pk_and_sequence_for(table)
          elsif @connection.respond_to?(:primary_key)
            pk = @connection.primary_key(table)
          end

          tbl.print "  create_table #{remove_prefix_and_suffix(table).inspect}"
          if columns.detect { |c| c.name == pk }
            if pk != 'id'
              tbl.print %Q(, :primary_key => "#{pk}")
            end
          else
            tbl.print ", :id => false"
          end
          tbl.print ", :force => true"
          tbl.print ", :options => \"ENGINE=#{@connection.engine(table)}\"" if @connection.respond_to?(:engine)
          tbl.puts " do |t|"

          # then dump all non-primary key columns
          column_specs = columns.map do |column|
            raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
            next if column.name == pk
            spec = {}
            spec[:name]      = column.name.inspect

            # AR has an optimization which handles zero-scale decimals as integers. This
            # code ensures that the dumper still dumps the column as a decimal.
            spec[:type]      = if column.type == :integer && [/^numeric/, /^decimal/].any? { |e| e.match(column.sql_type) }
                                 'decimal'
                               else
                                 column.type.to_s
                               end
            spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && spec[:type] != 'decimal'
            spec[:precision] = column.precision.inspect if column.precision
            spec[:scale]     = column.scale.inspect if column.scale
            spec[:null]      = 'false' unless column.null
            spec[:default]   = default_string(column.default) if column.has_default?
            (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
            spec
          end.compact

          # find all migration keys used in this table
          keys = [:name, :limit, :precision, :scale, :default, :null] & column_specs.map{ |k| k.keys }.flatten

          # figure out the lengths for each column based on above keys
          lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

          # the string we're going to sprintf our values against, with standardized column widths
          format_string = lengths.map{ |len| "%-#{len}s" }

          # find the max length for the 'type' column, which is special
          type_length = column_specs.map{ |column| column[:type].length }.max

          # add column type definition to our format string
          format_string.unshift "    t.%-#{type_length}s "

          format_string *= ''

          column_specs.each do |colspec|
            values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
            values.unshift colspec[:type]
            tbl.print((format_string % values).gsub(/,\s*$/, ''))
            tbl.puts
          end

          tbl.puts "  end"
          tbl.puts

          indexes(table, tbl)

          tbl.rewind
          stream.print tbl.read
        rescue => e
          stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
          stream.puts "#   #{e.message}"
          stream.puts
        end

        stream
      end

      def indexes(table, stream)
        if (indexes = @connection.indexes(table)).any?
          add_index_statements = indexes.map do |index|
            statement_parts = [
              ('add_index ' + remove_prefix_and_suffix(index.table).inspect),
              index.columns.inspect,
              (':name => ' + index.name.inspect),
            ]
            statement_parts << ':unique => true' if index.unique
            statement_parts << ':fulltext => true' if index.fulltext
            statement_parts << ":comment => '#{index.index_comment}'" unless index.index_comment.empty?

            index_lengths = (index.lengths || []).compact
            statement_parts << (':length => ' + Hash[index.columns.zip(index.lengths)].inspect) unless index_lengths.empty?

            index_orders = (index.orders || {})
            statement_parts << (':order => ' + index.orders.inspect) unless index_orders.empty?

            '  ' + statement_parts.join(', ')
          end

          stream.puts add_index_statements.sort.join("\n")
          stream.puts
        end
      end
  end
end
