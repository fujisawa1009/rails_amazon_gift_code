# Amazonインセンティブ APIとの通信を担当するサービスクラス
# - AGCODServiceRubyClientのラッパー
# - 認証情報の管理
# - APIレスポンスのパース処理
# - エラーハンドリング

class AmazonGiftCodeService
    def initialize
      @client = AGCODServiceRubyClient.new
    end
  
    def create_gift_code
      response = @client.create_gift_card
      # レスポンスからギフトコードを抽出する処理
      response.dig('CreateGiftCardResponse', 'gcId')
    end
  end
  