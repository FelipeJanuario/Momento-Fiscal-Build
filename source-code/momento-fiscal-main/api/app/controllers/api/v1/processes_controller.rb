# frozen_string_literal: true

module Api
  module V1
    # ProcessesController
    class ProcessesController < ApplicationController
      def show
        cpf_cnpj = params[:cpf_cnpj]
        search_after = params[:search_after]
        return render json: { error: "CPF/CNPJ é obrigatório" }, status: :bad_request if cpf_cnpj.blank?

        processes = JusbrasilService.fetch_processes(cpf_cnpj, search_after)

        return render json: { error: "Erro ao buscar processos" }, status: :internal_server_error if processes.nil?

        return render json: processes[:data], status: :ok if processes[:status] == :success

        if processes[:status] == :not_found
          return render json: { error: "Processos não encontrados" }, status: :not_found
        end

        render json: { error: "Erro ao buscar processos" }, status: :internal_server_error
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
