# frozen_string_literal: true

# Invitation
class Invitation < ApplicationRecord
  belongs_to :user, optional: true
  enum :status, { pending: 0, accepted: 1, declined: 2 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create :set_sent_at

  private

  def set_sent_at
    self.sent_at ||= Time.current
  end
end
