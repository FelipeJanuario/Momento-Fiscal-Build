# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/processes" do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /api/v1/processes" do
    let(:cpf_cnpj) { "12345678901" }
    let(:search_after) { nil }

    context "when CPF/CNPJ is not provided" do
      it "returns 400 Bad Request with an appropriate message" do
        get "/api/v1/processes", params: { cpf_cnpj: nil }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "error" => "CPF/CNPJ é obrigatório" })
      end
    end

    context "when the service response is success" do
      let(:mock_response) { { status: :success, data: { "process" => "info" } } }

      it "returns 200 OK and the response body" do
        allow(JusbrasilService).to receive(:fetch_processes).and_return(mock_response)

        get "/api/v1/processes", params: { cpf_cnpj: cpf_cnpj, search_after: search_after }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq("process" => "info")
      end
    end

    context "when the service response is not_found" do
      let(:mock_response) { { status: :not_found, data: nil } }

      it "returns 404 Not Found and an error message" do
        allow(JusbrasilService).to receive(:fetch_processes).and_return(mock_response)

        get "/api/v1/processes", params: { cpf_cnpj: cpf_cnpj }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq({ "error" => "Processos não encontrados" })
      end
    end

    context "when the service response is a generic error" do
      let(:mock_response) { { status: :error, data: nil } }

      it "returns 500 Internal Server Error and a generic error message" do
        allow(JusbrasilService).to receive(:fetch_processes).and_return(mock_response)

        get "/api/v1/processes", params: { cpf_cnpj: cpf_cnpj }

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body).to eq({ "error" => "Erro ao buscar processos" })
      end
    end
  end
end
