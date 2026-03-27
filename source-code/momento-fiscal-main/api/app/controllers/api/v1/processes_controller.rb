# frozen_string_literal: true

module Api
  module V1
    # ProcessesController
    class ProcessesController < ApplicationController
      def show
        cpf_cnpj = params[:cpf_cnpj]
        return render json: { error: "CPF/CNPJ é obrigatório" }, status: :bad_request if cpf_cnpj.blank?

        result = JusbrasilService.fetch_processes(cpf_cnpj)

        case result[:status]
        when :success
          return render json: {
            total: result[:total] || 0,
            numberOfElements: result[:processos]&.size || 0,
            maxElementsSize: 10,
            searchAfter: nil,
            content: result[:processos] || []
          }, status: :ok
        when :service_unavailable
          return render json: { error: result[:message] }, status: :service_unavailable
        when :error
          return render json: { error: result[:message] }, status: :unprocessable_entity
        end

        # :not_found ou qualquer outro → lista vazia HTTP 200
        render json: {
          total: 0,
          numberOfElements: 0,
          maxElementsSize: 10,
          searchAfter: nil,
          content: []
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[ProcessesController] Erro inesperado: #{e.message}")
        render json: {
          total: 0,
          numberOfElements: 0,
          maxElementsSize: 10,
          searchAfter: nil,
          content: []
        }, status: :ok
      end

      def show_by_number
        numero_processo = params[:numero_processo]
        return render json: { error: "Número do processo é obrigatório" }, status: :bad_request if numero_processo.blank?

        # Remove formatação, deixa apenas os 20 dígitos
        clean_number = numero_processo.gsub(/\D/, '')
        
        if clean_number.length != 20
          return render json: { error: "Número do processo deve ter 20 dígitos" }, status: :bad_request
        end

        # Busca em TODOS os 91 tribunais
        result = JusbrasilService.fetch_by_numero(
          clean_number, 
          tribunais: JusbrasilService::TRIBUNAIS.keys,
          timeout: 20
        )

        return render json: { error: "Erro ao buscar processo" }, status: :internal_server_error if result.nil?

        if result[:status] == :success
          return render json: { 
            total: result[:total],
            processos: result[:processos],
            tribunais_consultados: result[:tribunais_consultados],
            erros: result[:erros]
          }, status: :ok
        end

        # Se não encontrou nada, retorna estrutura vazia
        render json: { 
          total: 0,
          processos: [],
          tribunais_consultados: result[:tribunais_consultados] || [],
          erros: result[:erros] || []
        }, status: :ok
      end
    end
  end
end
