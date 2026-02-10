require 'stripe'

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)

Stripe.max_network_retries = 5
Stripe.open_timeout = 5.seconds
Stripe.read_timeout = 5.seconds
Stripe.write_timeout = 5.seconds

Stripe.api_version = '2024-06-20'

Stripe.log_level = Rails.env.production? ? 'info' : 'debug'
