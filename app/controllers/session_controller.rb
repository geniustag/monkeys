class SessionController < ApplicationController
  skip_before_action :require_login_or_permission

  def login
    return if request.get?
    current_user = auth_login(params[:login], params[:password])
    return flash[:danger] = I18n.t(:login_failed) unless current_user
    flash[:info] = "Welcome!!"
    session[:user_id] = current_user.id 
    redirect_to root_path 
  end      
  
  def logout
    reset_session
    flash[:notice] = "已经登出"
    redirect_to root_path
  end 

  private
  def auth_login(login, password)
    u = Member.find_by(email: login)
    u ? u.authenticate(password) : nil
  end
end
