# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength
    # Controller to handle Stripe integration
    class StripeController < ApplicationController
      before_action :authenticate_user!
      before_action :create_stripe_customer

      def create_setup_intent
        setup_intent = Stripe::SetupIntent.create(customer: current_user.stripe_customer_id)

        render json: {
          payment_intent:  setup_intent["client_secret"],
          ephemeral_key:   ephemeral_key["secret"],
          customer:        current_user.stripe_customer_id,
          publishable_key:
        }
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # rubocop:disable Metrics/MethodLength
      def create_payment_intent
        payment_intent = Stripe::PaymentIntent.create(
          amount:                    "1000",
          currency:                  "brl",
          customer:                  current_user.stripe_customer_id,
          automatic_payment_methods: {
            enabled: true
          }
        )

        render json: {
          payment_intent:  payment_intent["client_secret"],
          ephemeral_key:   ephemeral["secret"],
          customer:        current_user.stripe_customer_id,
          publishable_key:
        }
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
      # rubocop:enable Metrics/MethodLength

      def list_setup_intents
        setup_intents = Stripe::SetupIntent.list({ customer: current_user.stripe_customer_id })

        render json: setup_intents
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def list_payment_methods
        payment_methods = Stripe::PaymentMethod.list({ customer: current_user.stripe_customer_id, type: "card" })

        render json: payment_methods
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def detach_payment_method
        payment_method = Stripe::PaymentMethod.detach(params[:id])

        render json: payment_method
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def create_subscription
        subscription = Stripe::Subscription.create(
          customer:         current_user.stripe_customer_id,
          currency:         "brl",
          items:            [{ price: params[:price_id] }],
          payment_behavior: "default_incomplete",
          payment_settings: { save_default_payment_method: "on_subscription" },
          expand:           ["latest_invoice.payment_intent"]
        )

        render json: {
          subscription_id: subscription["id"],
          clientSecret:    subscription["latest_invoice"]["payment_intent"]["client_secret"],
          ephemeral_key:   ephemeral_key["secret"],
          customer:        current_user.stripe_customer_id,
          publishable_key:
        }
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update_subscription
        subscription = Stripe::Subscription.update(
          params[:subscription_id], items: [{ id: params[:subs_id], price: params[:price_id] }]
        )

        render json: {
          subscription_id: subscription["id"]
        }
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def list_subscriptions
        subscriptions = Stripe::Subscription.list({ customer: current_user.stripe_customer_id })
        render json: subscriptions
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def current_subscription
        render json: current_user.active_stripe_subscription
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def enabled_features
        render json: current_user.enabled_features
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def cancel_subscription
        Stripe::Subscription.cancel(params[:id])
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def list_products
        render json: Stripe::Product.list({ active: true })
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def list_prices
        render json: Stripe::Price.list(product: params[:product_id], active: true)
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def create_stripe_customer
        current_user.create_stripe_customer if current_user.stripe_customer_id.blank?
      end

      def publishable_key
        ENV.fetch("STRIPE_PUBLISHABLE_KEY")
      end

      def ephemeral_key
        @ephemeral_key ||= Stripe::EphemeralKey.create(
          { customer: current_user.stripe_customer_id },
          { stripe_version: Stripe.api_version }
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
