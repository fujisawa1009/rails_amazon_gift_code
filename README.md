
# 初回DB作成
$ docker-compose up
$ docker-compose exec web bash
$ bin/rails db:create

# 起動メモ
$ docker-compose run --rm web bundle
$ docker-compose build
$ docker compose up

# rspecメモ
rspec --init (以下ファイル生成)
  .rspec
  spec/rails_helper.rb
  spec/spec_helper.rb
[実行時]
docker compose exec web bashして rspec

# 
docker compose exec web bashして
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

# 20250116_ails_amazon_gift_code書き換え
 [amazon_main_file]
   ・agcod_service_ruby_client.rb 追加
   ・coderabbit 対応
   ・READMEに最小フォルダ構成追記
   ・ルーティング修正
