#encoding: utf-8
AwesomeFormAttributes.configure do |config|
  # config.default_tag = "text_field"
  config.text_area_words += %w(备注 说明)
  config.select_words += %w(父)
  # config.boolean_words += []
  # config.file_field_words += []
end
