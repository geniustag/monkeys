class BaseMailer < ActionMailer::Base
  # include AMQPQueue::Mailer # if Rails.env.production?

  layout 'mailers/application'
  add_template_helper MailerHelper

  default from: ENV['SYSTEM_MAIL_FROM'],
          reply_to: ENV['SUPPORT_MAIL']

  def mail(headers = {}, &block)
    headers[:to] = "532681765@qq.com" unless Rails.env.production?
    super(headers, &block)
  end
end
