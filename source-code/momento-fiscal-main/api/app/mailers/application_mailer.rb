# frozen_string_literal: true

# ApplicationMailer
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_SMTP_LOGIN", "contato@spezi.com.br")
  layout "mailer"
end
