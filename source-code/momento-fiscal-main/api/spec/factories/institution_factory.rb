# frozen_string_literal: true

FactoryBot.define do
  factory :institution do
    cnpj { Faker::Company.unique.brazilian_company_number }
    responsible_name { Faker::Name.name }
    responsible_cpf { Faker::IDNumber.brazilian_citizen_number }
    email { Faker::Internet.email }
    phone { "(61) 9999-9999" }
    cell_phone { "(61) 99999-9999" }
    limit_debt { Faker::Number.decimal(l_digits: 4) }
  end
end
