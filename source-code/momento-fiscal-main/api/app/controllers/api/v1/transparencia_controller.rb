# frozen_string_literal: true

module Api
  module V1
    # Controller para consultas ao Portal da Transparência (sanções)
    class TransparenciaController < ApplicationController
      # GET /api/v1/transparencia/sancoes/:cpf_cnpj
      def sancoes
        cpf_cnpj = params[:cpf_cnpj]

        if cpf_cnpj.blank?
          return render json: { error: "CPF/CNPJ é obrigatório" }, status: :bad_request
        end

        resultado = PortalTransparenciaService.consultar_sancoes(cpf_cnpj)

        render json: {
          cpf_cnpj: cpf_cnpj,
          sancoes: resultado[:sancoes],
          total: resultado[:total],
          from_cache: resultado[:from_cache]
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[TransparenciaController] Erro: #{e.message}")
        render json: { error: "Erro ao consultar sanções" }, status: :internal_server_error
      end
    end
  end
end
