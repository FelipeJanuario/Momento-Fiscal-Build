# frozen_string_literal: true

json.extract! notification, :id, :user_id, :title, :content, :redirect_to, :read_at, :created_at, :updated_at
json.url api_v1_notification_url(notification, format: :json)
