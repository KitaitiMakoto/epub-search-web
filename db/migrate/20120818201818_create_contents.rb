class CreateContents < ActiveRecord::Migration
  def up
    create_table :contents, options: 'ENGINE=mroonga CHARACTER SET utf8 COLLATE utf8_general_ci' do |t|
      t.text :content
      t.integer :book_id

      t.timestamps
    end

    add_index :contents, :book_id, null: false
    add_foreign_key :contents, :books
    add_index :contents, :content, fulltext: true, comment: 'parser "TokenMecab"'
  end

  def down
    drop_table :contents
  end
end
