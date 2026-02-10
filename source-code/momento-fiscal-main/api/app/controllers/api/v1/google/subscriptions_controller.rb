# frozen_string_literal: true

module Api
  module V1
    module Google
      # Controller to handle Biddings Analyser requests
      class SubscriptionsController < ApplicationController
        PACKAGE_NAME = ENV.fetch("GOOGLE_PLAY_PACKAGE_NAME", "br.com.momentofiscal").freeze

        def available_subscriptions
          response = publisher_service.list_monetization_subscriptions(PACKAGE_NAME)
          render json: response
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def acknowledge_subscription
          params.require(:subscription_id, :purchase_token)

          Google::Subscription.transaction do
            current_user.google_subscription&.destroy! if current_user.google_subscription.present?

            current_user.create_google_subscription!(
              subscription_id: params[:subscription_id],
              purchase_token:  params[:purchase_token]
            )

            publisher_service.acknowledge_subscription_purchase(
              PACKAGE_NAME,
              params[:subscription_id],
              params[:purchase_token],
              ::Google::Apis::AndroidpublisherV3::SubscriptionPurchasesAcknowledgeRequest.new
            )
          end

          render json: { message: "Subscription acknowledged successfully" }, status: :ok
        rescue StandardError => e
          Rails.logger.error("Error acknowledging Google subscription: #{e.message}")
          render json: { error: "Failed to acknowledge subscription" }, status: :unprocessable_entity
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def upgrade_subscription
          current_subscription_id = current_user.google_subscription&.subscription_id
          new_subscription_id     = params.require(:new_subscription_id)
          purchase_token          = params.google_subscription&.purchase_token

          if current_subscription_id.nil? || purchase_token.nil?
            render json: { error: "Current subscription not found" }, status: :not_found
            return
          end

          response = publisher_service.defer_subscription_purchase(
            PACKAGE_NAME,
            current_subscription_id,
            purchase_token,
            ::Google::Apis::AndroidpublisherV3::SubscriptionPurchasesDeferRequest.new(
              new_subscription_id: new_subscription_id
            )
          )
          render json: response
        rescue StandardError => e
          Rails.logger.error("Error upgrading Google subscription: #{e.message}")
          render json: { error: "Failed to upgrade subscription" }, status: :unprocessable_entity
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        def cancel_subscription
          subscription_id = params.require(:subscription_id)
          purchase_token  = params.require(:purchase_token)

          publisher_service.cancel_subscription_purchase(PACKAGE_NAME, subscription_id, purchase_token)
          render json: { message: "Subscription cancelled successfully" }, status: :ok
        rescue StandardError => e
          Rails.logger.error("Error cancelling Google subscription: #{e.message}")
          render json: { error: "Failed to cancel subscription" }, status: :unprocessable_entity
        end

        private

        def publisher_service
          @publisher_service ||= ::Google::Apis::AndroidpublisherV3::AndroidPublisherService.new.tap do |service|
            scope = ::Google::Apis::AndroidpublisherV3::AUTH_ANDROIDPUBLISHER
            access_token = fetch_access_token(scope)
            service.authorization = access_token
          end
        end

        def fetch_access_token(scope)
          access_token = Rails.cache.read("google_api_access_token_#{scope}")
          return access_token if access_token.present?

          account_credentials = ::Google::AuthService.new(scope).call

          Rails.cache.write("google_api_access_token_#{scope}", account_credentials.access_token,
                            expires_in: account_credentials.expires_in.seconds)
          account_credentials.access_token
        rescue StandardError => e
          Rails.logger.error("Error fetching Google API access token: #{e.message}")
          render json: { error: "Failed to authenticate with Google API" }, status: :unauthorized
        end
      end
    end
  end
end
