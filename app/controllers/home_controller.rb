class HomeController < ApplicationController
  layout :false

  skip_before_action :require_login_or_permission

  def index
    aff_id = request.url.split("code=").last.to_i.to_s(16)
    @aff_data = "#{"0" * (64 - aff_id.size)}#{aff_id}"
  end
end
