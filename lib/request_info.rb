module RequestInfo
  extend ActiveSupport::Concern

  included do
    helper_method :from_mobile?, :from_android?, :from_ios?, :from_app?, :from_weixin?
  end

  def from_weixin?
    request.user_agent.to_s.match(/MicroMessenger/)
  end

  def from_ios?
    request.user_agent.to_s.downcase =~ /ios|iphone|ipad|ipod/
  end

  def from_android?
    request.user_agent.to_s.downcase =~ /android/
  end

  def from_mobile?
    from_android? || from_ios?
  end

  def from_app?
    from_mobile? && 
      request.headers["Tonce"].presence &&
      request.user_agent.to_s =~ /gstwallet|Grearn/
  end

  def app_version
    return "0" if !from_app?
    from_android? and return request.user_agent.to_s.split(";")[-2]
    from_ios? and return request.user_agent.split("v-")[1]
  end

  def android_sdk_verion
    from_android? and return (request.user_agent.to_s.match(/Android(\d+)/)[1].to_i rescue 0)
    0
  end

  def client_type
    from_ios? and return "ios"
    from_android? and return "android"
    from_mobile? and return "mobile"
    "pc"
  end
end
