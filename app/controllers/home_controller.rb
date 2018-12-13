class HomeController < ApplicationController
  layout :false

  skip_before_action :require_login_or_permission

  def index
  end
end
