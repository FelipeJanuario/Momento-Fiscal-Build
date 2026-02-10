# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    cpf { Faker::IDNumber.brazilian_citizen_number }
    email { Faker::Internet.email }
    phone { "(61) 99999-9999" }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 65) }
    sex { User.sexes.values.sample }
    role { 0 }
    password { "password" }
    password_confirmation { "password" }
  end
end
