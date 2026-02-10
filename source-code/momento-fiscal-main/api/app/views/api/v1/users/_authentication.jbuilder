# frozen_string_literal: true

json.extract! user, :id, :name, :email, :cpf, :phone, :sex, :role, :birth_date, :oab_subscription, :oab_state,
              :stripe_customer_id, :ios_plan, :created_at, :updated_at

json.stripe_active_entitlements user.stripe_active_entitlements

json.is_admin user.admin?

json.token user.token
