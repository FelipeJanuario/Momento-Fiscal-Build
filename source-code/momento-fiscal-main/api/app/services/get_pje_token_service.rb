# frozen_string_literal: true

# Class that renders a PDF file from a template
class GetPjeTokenService < ApplicationService
  PJE_JWT_TOKEN_KEY = "pje_jwt_token"

  def initialize(**, &); end

  def call
    @token = Rails.cache.read(PJE_JWT_TOKEN_KEY)

    return @token if token_valid?

    Rails.logger.debug("[GetPjeTokenService] Token not found or expired. Fetching new token")

    @token = AuthenticatePjeService.new.call

    token_expires_at = JWT.decode(@token, nil, false)[0]["exp"]

    Rails.cache.write(PJE_JWT_TOKEN_KEY, @token, expires_at: Time.zone.at(token_expires_at))

    @token
  end

  private

  def token_valid?
    return false if @token.nil?

    decoded_token = JWT.decode(@token, nil, false).first

    decoded_token["exp"] > Time.now.to_i
  end
end
