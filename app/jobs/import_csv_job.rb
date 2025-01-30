class ImportCsvJob < ApplicationJob
  require 'csv'  # この行を追加  
  queue_as :default
    
    def perform(csv_import_id)
      csv_import = CsvImport.find(csv_import_id)
      csv_import.processing!
      
      begin
        process_csv(csv_import)
        csv_import.completed!
      rescue => e
        csv_import.failed!
        Rails.logger.error("CSV Import failed: #{e.message}")
        raise e
      end
    end
  
    private
  
    def process_csv(csv_import)
      CSV.parse(csv_import.file.download, headers: true) do |row|
        ActiveRecord::Base.transaction do
          # ここでデータを保存する処理を実装
          create_record_from_row(row)
        end
      end
    end
  
    # crypted_passwordとsaltはsorceryが自動的に処理するため、直接設定不要
    def create_record_from_row(row)
        # レコードの作成ロジック
        User.create!(
          email: row['email'],
          name: row['name'],
          password: generate_temporary_password,  # パスワードは必須なので一時的なものを生成
          apassword_confirmation: generate_temporary_password
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Row import failed: #{row.to_h} - CSV_Import_Error: #{e.message}")
        raise e
      end
  end
  
  private

  def generate_temporary_password
    SecureRandom.hex(8) # 16文字のランダムなパスワードを生成
  end