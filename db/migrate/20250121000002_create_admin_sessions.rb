
class CreateAdminSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_sessions do |t|
      t.references :administrator, null: false, foreign_key: true
      t.string :session_token, null: false
      t.timestamp :expires_at, null: false
      t.timestamps
    end
    add_index :admin_sessions, :session_token, unique: true
  end
end
