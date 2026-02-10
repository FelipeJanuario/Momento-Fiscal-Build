# frozen_string_literal: true

FactoryBot.define do
  factory :consulting do
    client factory: %i[user]
    consultant factory: %i[user]
    sent_at { Time.current }
    status { :not_started }
    value { 1000.0 }
  end
end
