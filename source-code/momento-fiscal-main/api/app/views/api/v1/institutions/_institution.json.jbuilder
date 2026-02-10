# frozen_string_literal: true

json.extract! institution, :id, :cnpj, :responsible_name, :responsible_cpf, :email, :phone, :cell_phone, :limit_debt,
              :created_at, :updated_at
json.url api_v1_institution_url(institution, format: :json)
