# frozen_string_literal: true

FactoryBot.define do
  factory :user_institution do
    role { :consultant }
    user
    institution
  end
end
