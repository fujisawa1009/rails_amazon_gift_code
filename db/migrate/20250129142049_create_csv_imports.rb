class CreateCsvImports < ActiveRecord::Migration[7.0]
  def change
    create_table :csv_imports do |t|
      t.string :status, null: false, default: 'pending'
      t.integer :imported_count, default: 0
      t.text :error_messages

      t.timestamps
    end
  end
end
