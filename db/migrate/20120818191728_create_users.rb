class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, options: 'DEFAULT CHARSET=UTF8' do |t|
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true
  end
end
