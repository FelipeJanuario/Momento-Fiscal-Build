# frozen_string_literal: true

# SerproAuthService
class SerproAuthService
  AUTH_URL = "https://gateway.apiserpro.serpro.gov.br/token"

  class << self
    def fetch_access_token
      authenticate if @access_token.nil? || token_expired?
      @access_token
    end

    private

    def authenticate
      response = send_authentication_request
      handle_authentication_response(response)
    end

    def send_authentication_request
      uri = URI(AUTH_URL)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(ENV.fetch("SERPRO_CONSUMER_KEY"), ENV.fetch("SERPRO_CONSUMER_SECRET"))
      request.set_form_data("grant_type" => "client_credentials")

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    end

    def handle_authentication_response(response)
      raise "Authentication failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      @access_token = body["access_token"]
      @token_expiry = Time.zone.now + body["expires_in"].to_i
    end

    def token_expired?
      @token_expiry.nil? || Time.zone.now >= @token_expiry
    end
  end
end
