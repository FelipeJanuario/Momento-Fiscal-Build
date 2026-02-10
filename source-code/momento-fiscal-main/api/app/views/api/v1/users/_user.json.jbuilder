# frozen_string_literal: true

json.extract! user, :id, :name, :email, :cpf, :phone, :sex, :role, :birth_date, :oab_subscription, :oab_state,
              :stripe_customer_id, :ios_plan, :created_at, :updated_at

json.url api_v1_user_url(user, format: :json)

json.token user.token
