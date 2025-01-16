class Admin::BaseController < ApplicationController
    before_action :require_admin
    layout 'admin'
    
    private
    
    def require_admin
      unless current_user&.admin?
        redirect_to login_path, alert: '管理者権限が必要です'
      end
    end
  end
  