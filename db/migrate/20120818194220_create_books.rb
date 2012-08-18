class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.string :file

      t.timestamps
    end

    add_index :books, :title
    add_index :books, :author
    add_index :books, :file, unique: true
  end
end
