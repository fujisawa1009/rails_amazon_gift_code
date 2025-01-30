# == Schema Information
#
# Table name: csv_imports
#
#  id             :bigint           not null, primary key
#  error_messages :text(65535)
#  imported_count :integer          default(0)
#  status         :string(255)      default(NULL), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class CsvImport < ApplicationRecord
    has_one_attached :file
    validates :file, presence: true
    
    enum status: {
      pending: 0,
      processing: 1,
      completed: 2,
      failed: 3
    }
  
    def process_import
      ImportCsvJob.perform_later(id)
    end
  end
  
