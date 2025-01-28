
class Admin::AdministratorsController < Admin::BaseController
  def index
    @administrators = Administrator.order(created_at: :desc)
  end

  def edit
    @administrator = current_user
  end

  def update
    @administrator = current_user
    if @administrator.update(administrator_params)
      flash.now[:success] = 'プロフィールを更新しました'
      render :edit, status: :ok
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def administrator_params
    params.require(:administrator).permit(:email, :password, :password_confirmation)
  end
end
