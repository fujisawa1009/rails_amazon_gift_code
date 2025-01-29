# Day 1-2の「大規模CSVインポート」の実装課題と解答

目的: 大量のデータを含むCSVファイルを非同期でインポートできるシステムの構築

要件:
CSVファイルをブラウザからアップロード可能
Active Storageを使用してファイルを保存
Sidekiqを使用して非同期でインポート処理を実行
インポート進捗状況の表示
エラーハンドリングとリトライ機能の実装

モデル設計
```
class CsvUpload < ApplicationRecord
  has_one_attached :csv_file
  validates :csv_file, presence: true
  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }
end

```

ジョブ実装
```
class ImportCsvJob < ApplicationJob
  queue_as :default
  
  def perform(csv_upload_id)
    csv_upload = CsvUpload.find(csv_upload_id)
    csv_upload.processing!
    
    CSV.parse(csv_upload.csv_file.download, headers: true) do |row|
      # レコードの作成処理
    end
    
    csv_upload.completed!
  rescue => e
    csv_upload.failed!
    raise e
  end
end

```
サンプルリポジトリ
GitHubリポジトリ: rails-csv-import-sample
https://github.com/yourusername/rails-csv-import-sample
```
app/
  ├── controllers/
  │   └── csv_uploads_controller.rb
  ├── jobs/
  │   └── import_csv_job.rb
  ├── models/
  │   └── csv_upload.rb
  └── views/
      └── csv_uploads/
          ├── new.html.erb
          └── show.html.erb

```

```作成手順メモ
bin/rails g model csv_import

app/jobs/import_csv_job.rb

bin/rails g controller csv_imports_controller

app/views/csv_imports/new.html.erb

app/views/csv_imports/show.html.erb

resources :csv_imports, only: [:new, :create, :show]

config/sidekiq.yml
```

# ユーザーデータのインポート例　
app/jobs/import_csv_job.rb
```
def create_record_from_row(row)
  User.create!(
    name: row['name'],
    email: row['email'],
    age: row['age'],
    address: row['address']
  )
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("Row import failed: #{row.to_h} - Error: #{e.message}")
  raise e
end

```

# 画面テスト手順
