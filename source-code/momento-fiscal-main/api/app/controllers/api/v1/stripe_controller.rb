# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength
    # Controller to handle Stripe integration
    class StripeController < ApplicationController
      before_action :authenticate_user!, except: [:webhook]
      before_action :create_stripe_customer, except: [:webhook]

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

      # rubocop:disable Metrics/MethodLength
      def create_checkout_session
        base_url    = ENV.fetch("APP_BASE_URL", "https://momentofiscal.com.br")
        success_url = params[:success_url].presence || "#{base_url}/payment/success?session_id={CHECKOUT_SESSION_ID}"
        cancel_url  = params[:cancel_url].presence  || "#{base_url}/payment/cancel"

        session = Stripe::Checkout::Session.create(
          customer:             current_user.stripe_customer_id,
          mode:                 "subscription",
          line_items:           [{ price: params[:price_id], quantity: 1 }],
          success_url:          success_url,
          cancel_url:           cancel_url,
          locale:               "pt-BR",
          allow_promotion_codes: true
        )

        render json: { checkout_url: session.url }
      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def webhook
        payload = request.body.read
        sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
        endpoint_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", "")

        begin
          event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
        rescue JSON::ParserError
          return head :bad_request
        rescue Stripe::SignatureVerificationError
          return head :bad_request
        end

        handle_webhook_event(event)
        head :ok
      end
      # rubocop:enable Metrics/MethodLength

      private

      def handle_webhook_event(event)
        case event.type
        when "checkout.session.completed"
          handle_checkout_completed(event.data.object)
        when "customer.subscription.updated"
          handle_subscription_updated(event.data.object)
        when "customer.subscription.deleted"
          handle_subscription_deleted(event.data.object)
        when "invoice.payment_failed"
          handle_payment_failed(event.data.object)
        end
      end

      def handle_checkout_completed(session)
        user = User.find_by(stripe_customer_id: session.customer)
        return unless user

        user.update(subscription_status: "active")
        Rails.logger.info("[Stripe Webhook] Checkout completed for user #{user.id}")
      end

      def handle_subscription_updated(subscription)
        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        user.update(subscription_status: subscription.status)
        Rails.logger.info("[Stripe Webhook] Subscription #{subscription.id} updated to #{subscription.status}")
      end

      def handle_subscription_deleted(subscription)
        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        user.update(subscription_status: "canceled")
        Rails.logger.info("[Stripe Webhook] Subscription #{subscription.id} canceled for user #{user.id}")
      end

      def handle_payment_failed(invoice)
        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        user.update(subscription_status: "past_due")
        Rails.logger.info("[Stripe Webhook] Payment failed for user #{user.id}, invoice #{invoice.id}")
      end

      def create_stripe_customer
        if current_user.stripe_customer_id.present?
          begin
            Stripe::Customer.retrieve(current_user.stripe_customer_id)
          rescue Stripe::InvalidRequestError
            # ID inválido (outro ambiente/conta) — limpa e recria
            current_user.update_column(:stripe_customer_id, nil)
            current_user.create_stripe_customer
          end
        else
          current_user.create_stripe_customer
        end
      rescue StandardError => e
        Rails.logger.error("[StripeController] Erro ao configurar cliente Stripe: #{e.message}")
        render json: { error: 'Erro ao configurar conta Stripe. Tente novamente.' }, status: :unprocessable_entity
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
