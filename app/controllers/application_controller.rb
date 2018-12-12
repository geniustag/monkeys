class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include AuthenticatedSystem, SharedHelper
  before_action :require_login_or_permission
  ActionController::Parameters.permit_all_parameters = true

  include RequestInfo #, Exceptionable, RequestMoniter, Clientable

  helper_method :from_weixin?

  def from_weixin?
    request.user_agent.to_s.match(/MicroMessenger/)
  end

  private
    def require_login_or_permission
      !request.user_agent.presence and return render(text: "OK")
      session[:redirect_to] = request.url
      return redirect_to login_path unless session[:user_id]
      return true if current_user && (current_user.can_access?(request.path) || current_user.is_admin?)
      flash[:danger] = I18n.t(:permission_denied)
      redirect_to URI(session[:redirect_to]).path == root_path ? "/login" : session[:redirect_to]
    end

    def back_to_list(condition = true, msg = nil)
      return render(:edit) unless condition
      flash[condition ? :info : :danger] = 
        condition ? "操作成功" : single_obj.errors.full_messages.join("\n")
      flash[:info] = msg if msg
      redirect_to(action: :index)
    end

    def to_or_not_to?(obj)
      obj.save ? back_to_list("OK") : render(:new) 
    end

    def auth_admin
      !current_user and return false
      return true if current_user.try(:is_admin?)
      flash[:danger] = I18n.t(:permission_denied)
      redirect_to root_path
    end
end
