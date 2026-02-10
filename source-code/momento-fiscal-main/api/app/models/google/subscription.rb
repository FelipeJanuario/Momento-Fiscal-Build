# frozen_string_literal: true

module Google
  # Subscription model for Google-related subscriptions
  class Subscription < ApplicationRecord
    self.table_name_prefix = "google_"

    belongs_to :user, inverse_of: :google_subscription
  end
end
