# frozen_string_literal: true

json.extract! user_institution, :id, :role, :user_id, :institution_id, :created_at, :updated_at

json.url api_v1_user_url(user_institution, format: :json)
