
# 初回DB作成
$ docker-compose up

$ docker-compose exec web bash

$ bin/rails db:create

# 起動メモ
$ docker-compose run --rm web bundle

$ docker-compose build

$ docker compose up

# http://localhost:3001/ root設定内容
-- コンテナログ
$ docker compose logs web

-- Dockerfile等変更時
docker compose down
docker compose build
docker compose up -d

# rspecメモ
rspec --init (以下ファイル生成)
  .rspec
  spec/rails_helper.rb
  spec/spec_helper.rb
[実行時]
docker compose exec web bash して rspec

# rubocpメモ
docker compose exec web bash して

rubocop -a

# erb-lint ERBチェック
bundle exec erblint . -a

# 改修メモ
Gem を追加したので bundle install を実行してください

カラムを追加したので bin/rails db:migrate を実行してください

コマンドでの実行
gemインストール

docker-compose  run --rm web bundle

# コントローラ作成
docker compose exec web bash

bin/rails g controller users index

# モデル作成手順
docker compose exec web bash

bin/rails g model post

マイグレーションファイルを書き換える
bin/rails db:migrate

もしくは
docker-compose run web bundle exec rake db:migrate

# scaffoldingで一括作成時
bin/rails g scaffold question name:string title:string content:text 

bin/rails db:migrate

[最小構成]
```
app/
  ├── controllers/
  │   └── gift_codes_controller.rb # ギフトコード生成
  ├── views/
  │   └── gift_codes/
  │       └── index.html.erb　# ギフトコード生成のメイン画面
  └── services/
      └── amazon_gift_code_service.rb # Amazonインセンティブ APIとの通信するサービスクラス
lib/
  └── amazon/
      └── incentive_api/
          └── agcod_service_ruby_client.rb # Amazonインセンティブ APIの公式サンプルコード

```

# amazon_api利用のために環境変数設定が必要
$ EDITOR="code --wait" rails credentials:edit

$ export EDITOR="code --wait"  # VS Codeの場合

$ source ~/.bashrc  # または source ~/.zshrc

# credentialsファイルを編集

$ EDITOR="vi" rails credentials:edit
--- vi がない場合は以下
  apt-get update
  apt-get install vim

[設定内容]
```
amazon_incentive:
  partner_id: "YOUR_PARTNER_ID"
  aws_key_id: "YOUR_AWS_KEY_ID"
  aws_secret_key: "YOUR_AWS_SECRET_KEY"
  host: "agcod-v2-gamma.amazon.com"
  region: "us-east-1"

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: [既存の値をそのまま残す]
```
