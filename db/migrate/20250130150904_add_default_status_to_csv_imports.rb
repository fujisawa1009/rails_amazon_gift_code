class AddDefaultStatusToCsvImports < ActiveRecord::Migration[7.0]
  def change
    change_column_default :csv_imports, :status, from: nil, to: 0
    change_column_null :csv_imports, :status, false
  end
end
