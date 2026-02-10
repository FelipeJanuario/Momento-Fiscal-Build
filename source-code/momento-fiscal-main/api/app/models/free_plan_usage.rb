# frozen_string_literal: true

# Free Plan Usage
class FreePlanUsage < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  enum :status, { active: "active", expired: "expired", upgraded: "upgraded" }
end
