# db/migrate/20250121000006_add_crypted_password_and_salt_to_users.rb
class AddCryptedPasswordAndSaltToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :crypted_password, :string unless column_exists?(:users, :crypted_password)
    add_column :users, :salt, :string unless column_exists?(:users, :salt)
  end
end
