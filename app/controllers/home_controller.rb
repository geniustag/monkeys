class HomeController < ApplicationController
  before_action :require_login_or_permission, :filter_outer, only: :index

  def index
    if q = params[:q].presence
      a = q.split.join
      @results = [
        Member.where("phone_number like '#{q}%' or email like '#{q}%'"),
        Account.where("address like '#{q}%'")
      ]
    end
  end

  def privacy
    render layout: false
  end

  def about
    render layout: false
  end

  def app_downloads
    @version = AppVersion.last_version_info(from_android? ? "android" : "ios")
    render layout: false
  end

  def apps
    @version = AppVersion.last_version_info(from_android? ? "android" : "ios")
    render layout: "h5"
  end
end
