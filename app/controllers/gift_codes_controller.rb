class GiftCodesController < ApplicationController
    def index
    end
  
    def create
      service = AmazonGiftCodeService.new
      @gift_code = service.create_gift_code
      render json: { code: @gift_code }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  