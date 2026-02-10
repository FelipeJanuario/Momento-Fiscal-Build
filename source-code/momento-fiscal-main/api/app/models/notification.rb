# frozen_string_literal: true

# Path: api/app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  after_create :send_email, if: :validate_send_email

  def read!
    update(read_at: Time.zone.current)
  end

  def send_email
    NotificationsMailer.email_notification(self).deliver_later
  end

  def validate_send_email
    user.enabled_features.include?("email_notification")
  end
end
