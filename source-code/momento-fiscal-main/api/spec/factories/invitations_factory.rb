# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    email { "teste@gmail.com" }
    status { 1 }
    sent_at { "2024-09-11 19:36:39" }
  end
end
