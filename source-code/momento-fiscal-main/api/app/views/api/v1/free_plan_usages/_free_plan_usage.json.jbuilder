# frozen_string_literal: true

json.extract! free_plan_usage, :id, :user_id, :status, :created_at, :updated_at
json.url api_v1_free_plan_usage_url(free_plan_usage, format: :json)
