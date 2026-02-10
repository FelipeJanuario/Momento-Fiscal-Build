# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    user { nil }
    title { "My test notification title" }
    content { "My test notification content" }
    redirect_to { Faker::Internet.url }
    read_at { "2024-10-04 17:57:33" }
  end
end
