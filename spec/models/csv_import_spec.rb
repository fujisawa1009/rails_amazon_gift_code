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
require 'rails_helper'

RSpec.describe CsvImport, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:file) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      pending: 'pending',
      processing: 'processing',
      completed: 'completed',
      failed: 'failed'
    ) }
  end

  describe '#process_import' do
    let(:csv_import) { create(:csv_import) }

    it 'enqueues ImportCsvJob' do
      expect {
        csv_import.process_import
      }.to have_enqueued_job(ImportCsvJob).with(csv_import.id)
    end
  end
end

