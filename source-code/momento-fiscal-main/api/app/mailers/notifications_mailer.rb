# frozen_string_literal: true

# NotificationsMailer
class NotificationsMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications_mailer.email_notification.subject
  #
  def email_notification(notification)
    @notification = notification

    mail to: @notification.user.email, subject: @notification.title || "Nova notificação - Momento Fiscal"
  end
end
