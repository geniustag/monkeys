module UrlTool
  def self.final_url(url, host = GlobalHost)
    url.to_s =~ /^http/ ? url : "#{host}#{url}"
  end

  def self.http_post_request(host, post_body)
    http    = Net::HTTP.new(host.host, host.port)
    request = Net::HTTP::Post.new(host.request_uri)
    request.basic_auth host.user, host.password
    request.content_type = 'application/json'
    request.body = post_body
    http.request(request).body
  rescue Errno::ECONNREFUSED => e
    raise ConnectionRefusedError
  end
end
