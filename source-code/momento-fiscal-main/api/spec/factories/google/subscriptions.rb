# frozen_string_literal: true

FactoryBot.define do
  factory :google_subscription, class: "Google::Subscription" do
    user { nil }
    subscription_id { "MyString" }
    purchase_token { "MyString" }
  end
end
