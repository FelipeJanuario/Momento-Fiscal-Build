# frozen_string_literal: true

json.array! @notifications, partial: "api/v1/notifications/notification", as: :notification
