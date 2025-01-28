
class CreateAdministrators < ActiveRecord::Migration[7.0]
  def change
    create_table :administrators do |t|
      t.string :email, null: false
      t.string :crypted_password
      t.string :salt
      t.string :reset_password_token
      t.timestamp :reset_password_sent_at
      t.integer :sign_in_count, null: false, default: 0
      t.timestamp :current_sign_in_at
      t.timestamp :last_sign_in_at
      t.timestamps
    end

    add_index :administrators, :email, unique: true
    add_index :administrators, :reset_password_token, unique: true
  end
end
