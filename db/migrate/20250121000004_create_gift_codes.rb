
class CreateGiftCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :gift_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :administrator, foreign_key: { to_table: :users }
      t.string :unique_url, null: false, limit: 32
      t.integer :status, null: false, default: 0
      t.string :creation_request_id, null: false, limit: 40
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :currency_code, null: false, limit: 3
      t.string :gc_id, null: false
      t.datetime :claimed_at
      t.datetime :expires_at, null: false
      
      t.timestamps
    end

    add_index :gift_codes, :unique_url, unique: true
    add_index :gift_codes, :creation_request_id, unique: true
  end
end
