# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidateOabSubscriptionService do
  describe "#call" do
    let(:oab) { "123456" }
    let(:name) { "John Doe" }
    let(:state) { "SP" }

    context "when oab is present" do
      it "returns true if SearchOabSubscriptionService finds a subscription" do
        allow(SearchOabSubscriptionService).to receive(:call).with(oab:, name:, state:).and_return([{ "Oab" => oab }])
        service = described_class.new(oab:, name:, state:)
        expect(service.call).to be true
      end

      it "returns false if SearchOabSubscriptionService does not find a subscription" do
        allow(SearchOabSubscriptionService).to receive(:call).with(oab:, name:, state:).and_return([])
        service = described_class.new(oab:, name:, state:)
        expect(service.call).to be false
      end
    end

    context "when oab is blank" do
      it "returns false without calling SearchOabSubscriptionService" do
        allow(SearchOabSubscriptionService).to receive(:call)

        service = described_class.new(oab: "", name:, state:)

        expect(service.call).to be false
        expect(SearchOabSubscriptionService).not_to have_received(:call)
      end
    end
  end
end
