# frozen_string_literal: true

require "rails_helper"

RSpec.describe JusbrasilService do
  let(:cpf_cnpj) { "12345678901" }
  let(:search_after) { nil }
  let(:uri) { URI("#{described_class::API_URL}?cpfCnpjParte=#{cpf_cnpj}&searchAfter=#{search_after}") }
  let(:token) { "fake_token" }

  let(:token_service) { instance_double(GetPjeTokenService, call: token) }

  before do
    allow(GetPjeTokenService).to receive(:new).and_return(token_service)
  end

  describe ".fetch_processes" do
    let(:request) { instance_double(Net::HTTP::Get) }
    let(:response) { instance_double(Net::HTTPSuccess, body: "{}", class: Net::HTTPSuccess) }
    let(:http) { instance_double(Net::HTTP) }

    before do
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)
    end

    context "when the API response is successful (200)" do
      let(:response_body) { { "process" => "details" }.to_json }
      let(:response) { instance_double(Net::HTTPSuccess, body: response_body) }

      before do
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      end

      it "returns a success status and parsed data" do
        result = described_class.fetch_processes(cpf_cnpj, search_after)

        expect(result[:status]).to eq(:success)
        expect(result[:data].to_json).to eq({ "process" => "details" }.to_json)
      end
    end

    context "when the API returns 404 Not Found" do
      let(:response) { instance_double(Net::HTTPNotFound, body: "Not Found") }

      before do
        allow(response).to receive(:is_a?).and_return(false)
        allow(response).to receive(:is_a?).with(Net::HTTPNotFound).and_return(true)
        allow(http).to receive(:request).and_return(response)
      end

      it "returns not_found status and nil data" do
        result = described_class.fetch_processes(cpf_cnpj, search_after)

        expect(result[:status]).to eq(:not_found)
        expect(result[:data]).to be_nil
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(described_class).to receive(:perform_request).and_raise(StandardError, "boom")
      end

      it "logs the error and returns nil" do
        allow(Rails.logger).to receive(:error)

        result = described_class.fetch_processes(cpf_cnpj, search_after)

        expect(Rails.logger).to have_received(:error).with(/Erro ao buscar processos: boom/)
        expect(result).to be_nil
      end
    end

    describe ".build_uri" do
      it "constructs the correct URI" do
        built_uri = described_class.build_uri(cpf_cnpj, search_after)
        expect(built_uri.to_s).to eq("#{described_class::API_URL}?cpfCnpjParte=#{cpf_cnpj}&searchAfter=#{search_after}")
      end
    end
  end
end
