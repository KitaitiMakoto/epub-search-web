class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.string :epub, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :books, :user_id
    add_index :books, :title
    add_index :books, :author
    add_index :books, :epub, unique: true
    add_foreign_key :books, :users
  end
end
