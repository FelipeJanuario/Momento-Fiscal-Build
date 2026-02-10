# frozen_string_literal: true

module Api
  # HealthController
  class HealthController < ApplicationController
    skip_before_action :authenticate_user!

    def show
      # Check for pending migrations (Rails 7.2 compatible)
      raise ActiveRecord::PendingMigrationError if ActiveRecord::Migration.check_all_pending!.present? rescue false

      payload = {
        name:      Rails.application.class.name.underscore.split("/").first,
        hostname:  Socket.gethostname,
        # revision:  Health.revision,
        pid:       Process.pid,
        parent_id: Process.ppid,
        platform:  { name: "rails", version: Rails.version }
      }

      render json: payload
    end
  end
end
