# frozen_string_literal: true

module Api
  module V1
    # NotificationsController
    class NotificationsController < ApplicationController
      before_action :set_notification, only: %i[show destroy]

      # GET /notifications
      # GET /notifications.json
      def index
        @notifications = Notification.query(params[:query])
                                     .order(created_at: :desc)
                                     .where(user: current_user)
                                     .paginate(page: params[:page], per_page: params[:per_page])
      end

      # GET /notifications/1
      # GET /notifications/1.json
      def show; end

      # DELETE /notifications/1
      # DELETE /notifications/1.json
      def destroy
        @notification.destroy!
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_notification
        @notification = Notification.where(user: current_user).find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def notification_params
        params.require(:notification).permit(:title, :content, :redirect_to, :read_at)
      end
    end
  end
end
