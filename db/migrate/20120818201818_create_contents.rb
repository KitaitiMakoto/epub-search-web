class CreateContents < ActiveRecord::Migration
  def up
    create_table :contents, options: 'ENGINE=mroonga' do |t|
      t.text :content
      t.integer :book_id

      t.timestamps
    end

    add_index :contents, :book_id
    execute 'create fulltext index `fulltext_index_on_content` on contents(`content`) COMMENT \'parser "TokenMecab"\''
  end

  def down
    drop_table :contents
  end
end
