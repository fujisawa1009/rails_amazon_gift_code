class Admin::SessionsController < Admin::BaseController
  skip_before_action :require_login, only: %i[new create]
  skip_before_action :check_admin, only: %i[new create]
  
  layout 'admin_login'  # ログイン用の別レイアウト

  def new; end

  def create
    @user = login(params[:email], params[:password])
    
    if @user&.admin?
      redirect_to admin_root_path, success: '管理者としてログインしました'
    else
      flash.now[:danger] = 'ログインに失敗しました'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to admin_login_path, success: 'ログアウトしました'
  end
end
