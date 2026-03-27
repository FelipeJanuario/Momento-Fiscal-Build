# frozen_string_literal: true

module Api
  module V1
    # Controller to handle Serpro integration
    class SerproController < ApplicationController
      # GET /api/v1/serpro/consulta_cpf/:cpf
      def consulta_cpf
        cpf = params[:cpf]

        dividas = SerproDividaAtivaService.fetch_dividas(cpf)

        if dividas.any?
          render json: dividas, status: :ok
        else
          render json: { error: "Nenhuma dívida encontrada" }, status: :not_found
        end
      rescue StandardError => e
        Rails.logger.error("[SerproController] Erro consulta_cpf: #{e.message}")
        render json: { error: "Erro ao consultar CPF" }, status: :internal_server_error
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
    end
  end
end
