# frozen_string_literal: true

module Api
  module V1
    # Controller to handle Serpro integration
    class SerproController < ApplicationController
      # GET /api/v1/serpro/consulta_cpf/:cpf
      def consulta_cpf
        cpf = params[:cpf]
        url = "https://gateway.apiserpro.serpro.gov.br/consulta-divida-ativa-df/api/v1/devedor/#{cpf}"

        response = make_request(url)

        if response.is_a?(Net::HTTPSuccess)
          render json: JSON.parse(response.body), status: :ok
        else
          render json: { error: response.body }, status: response.code.to_i
        end
      end

      # GET /api/v1/serpro/dividas/:cpf_cnpj
      # Retorna dívidas do Serpro com cálculo de valores
      def dividas
        cpf_cnpj = params[:cpf_cnpj]
        
        if cpf_cnpj.blank?
          return render json: { error: "CPF/CNPJ é obrigatório" }, status: :bad_request
        end

        resultado = SerproDividaAtivaService.fetch_and_update(cpf_cnpj)
        
        render json: {
          cpf_cnpj: cpf_cnpj,
          debt_count: resultado[:debt_count],
          debt_value: resultado[:debt_value],
          debts: resultado[:debts]
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[SerproController] Erro: #{e.message}")
        render json: { error: "Erro ao consultar dívidas" }, status: :internal_server_error
      end

      private

      def make_request(url)
        uri = URI(url)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{SerproAuthService.fetch_access_token}"

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end
    end
  end
end
