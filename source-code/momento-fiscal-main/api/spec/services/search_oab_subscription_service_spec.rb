# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchOabSubscriptionService do
  describe "#call" do
    let(:oab) { "123456" }
    let(:name) { "John Doe" }
    let(:state) { "SP" }
    let(:service) { described_class.new(oab:, name:, state:) }

    context "when valid parameters are provided" do
      before do
        stub_request(:post, "#{described_class::BASE_URL}Home/Search")
          .with(body: { Insc: oab, Uf: state, NomeAdvo: name, TipoInsc: "" })
          .to_return(body: { Data: [{ "Oab" => oab }] }.to_json)
      end

      it "returns the expected result" do
        expect(service.call).to eq([{ "Oab" => oab }])
      end
    end

    context "when invalid parameters are provided" do
      let(:oab) { "" } # Invalid OAB

      it "handles errors gracefully" do
        expect { service.call }.not_to raise_error
      end
    end
  end

  describe "#connection" do
    let(:service) { described_class.new(oab: "123456") }

    it "returns a Faraday connection object with the correct base URL" do
      expect(service.connection.url_prefix.to_s).to eq(described_class::BASE_URL)
    end
  end
end
