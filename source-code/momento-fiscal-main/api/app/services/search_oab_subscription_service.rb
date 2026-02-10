# frozen_string_literal: true

# ValidateCpfService
class SearchOabSubscriptionService < ApplicationService
  BASE_URL = "https://cna.oab.org.br/"

  def initialize(oab:, name: "", state: "")
    @oab = oab
    @name = name
    @state = state
  end

  def call
    return [] if @oab.blank?

    fetch_subscriptions
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :logger unless Rails.env.production?
    end
  end

  private

  def fetch_subscriptions
    response = connection.post(
      "/Home/Search",
      Insc:	    @oab,
      Uf:	      @state,
      NomeAdvo:	@name,
      TipoInsc:	""
    )

    JSON.parse(response.body)&.[]("Data")
  end
end
