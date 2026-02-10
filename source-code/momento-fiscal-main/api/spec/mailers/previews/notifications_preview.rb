# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/notifications
class NotificationsPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifications/email_notification
  def email_notification
    NotificationsMailer.email_notification
  end
end
