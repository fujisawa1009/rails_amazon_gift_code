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
FactoryBot.define do
  factory :csv_import do
    status { 'pending' }

    after(:build) do |csv_import|
      csv_import.file.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'users.csv')),
        filename: 'users.csv',
        content_type: 'text/csv'
      )
    end
  end
end
