# ベースイメージとしてRuby 3.1.1を使用
FROM ruby:3.1.1

# アプリケーションのルートディレクトリを設定
ARG ROOT="/rails_amazon_gift_code"

# 言語設定を日本語に設定
ENV LANG=C.UTF-8
# タイムゾーンを東京に設定
ENV TZ=Asia/Tokyo

# 作業ディレクトリを設定
WORKDIR ${ROOT}

# 必要なパッケージをインストール
# - mariadb-client: MySQLクライアント
# - tzdata: タイムゾーンデータ
# - libvips: 画像処理ライブラリ
RUN apt-get update; \
  apt-get install -y --no-install-recommends \
		mariadb-client tzdata libvips

# GemfileとGemfile.lockをコンテナにコピー
COPY Gemfile ${ROOT}
COPY Gemfile.lock ${ROOT}

# Bundlerをインストールし、依存関係をインストール
RUN gem install bundler
RUN bundle install --jobs 4

# コンテナ起動時に実行されるスクリプトをセットアップ
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Railsサーバーのポートを公開
EXPOSE 3000

# コンテナ起動時のメインプロセスを設定
# 0.0.0.0をバインドすることで外部からのアクセスを許可
CMD ["rails", "server", "-b", "0.0.0.0"]
