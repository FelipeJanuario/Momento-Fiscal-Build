# frozen_string_literal: true

# ValidateCpfService
class ValidateOabSubscriptionService < ApplicationService
  BASE_URL = "https://cna.oab.org.br"

  def initialize(oab:, name: "", state: "")
    @oab = oab
    @name = name
    @state = state
  end

  def call
    return false if @oab.blank?

    SearchOabSubscriptionService.call(oab: @oab, name: @name, state: @state).present?
  end
end
