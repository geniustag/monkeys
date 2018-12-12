module SunAdminHelper
  def upload_file_field(obj)
    image = image_tag(obj.avatar.thumb.url, width: 50, height: 50) 
    c = content_tag(:div, image, class: "choose_icon", id: "choose_image")
    content_tag(:div, c, class: "choose_file")
  end

  def values_for_columns(obj, wrapper = :td, style = {})
    join_content(wrapper, style) do |a|
      if klass.respond_to?(:special_display_attrs) && klass.special_display_attrs.include?(a.to_s)
        begin
          render "admin/#{controller_name}/special_display_attrs", obj: obj, attr_name: a
        rescue => e
          Rails.logger.info "#" * 100
          Rails.logger.info e.message
          render "shared/special_display_attrs", obj: obj, attr_name: a
        end
      else
        origin_value = obj.send(a)
        origin_value = origin_value.is_a?(Time) ? origin_value.strftime("%F %T") : origin_value
        mname = a.to_s =~ /_id$/ ? a.to_s.sub(/_id$/,"") : nil
        aa = %w(ask bid).include?(mname) ? "orders" : mname.try(:tableize)
        aa = "members" if mname =~ /member/
        raw a.to_s =~ /_id$/ ? link_to(obj.send(mname).try(:display_name), "/admin/#{aa}/#{origin_value}") : origin_value
      end
    end
  end
end
