class Admin::GiftCodesController < Admin::BaseController
    def create
      @user = User.find(params[:user_id])
      service = AmazonGiftCodeService.new
      @gift_code = @user.gift_codes.build(gift_code_params)
      
      if @gift_code.save
        result = service.create_gift_code(@gift_code)
        if result
          redirect_to admin_users_path, success: 'ギフトコードを作成しました'
        else
          @gift_code.destroy
          redirect_to admin_users_path, error: 'ギフトコードの作成に失敗しました'
        end
      end
    end
    
    private
    
    def gift_code_params
      params.require(:gift_code).permit(:amount, :currency_code)
    end
  end
  