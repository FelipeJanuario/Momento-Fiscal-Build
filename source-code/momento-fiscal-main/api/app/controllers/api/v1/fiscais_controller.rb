# frozen_string_literal: true

module Api
  module V1
    # Controller unificado para APIs fiscais (CAUC, SICONFI, SIAFI, FNDE)
    class FiscaisController < ApplicationController
      # GET /api/v1/fiscais/cauc/:cnpj
      def cauc
        cnpj = params[:cnpj]
        resultado = CaucService.consultar(cnpj)
        render json: resultado, status: :ok
      rescue StandardError => e
        Rails.logger.error("[FiscaisController] Erro CAUC: #{e.message}")
        render json: { error: "Erro ao consultar CAUC" }, status: :internal_server_error
      end

      # GET /api/v1/fiscais/siconfi/:codigo_ibge
      def siconfi
        codigo_ibge = params[:codigo_ibge]
        exercicio = params[:exercicio]&.to_i

        resultado = SiconfiService.consultar_por_ente(codigo_ibge, exercicio: exercicio)
        render json: resultado, status: :ok
      rescue StandardError => e
        Rails.logger.error("[FiscaisController] Erro SICONFI: #{e.message}")
        render json: { error: "Erro ao consultar SICONFI" }, status: :internal_server_error
      end

      # GET /api/v1/fiscais/transferencias/:cnpj
      def transferencias
        cnpj = params[:cnpj]
        ano = params[:ano]&.to_i

        resultado = SiafiService.consultar_transferencias(cnpj, ano: ano)
        render json: resultado, status: :ok
      rescue StandardError => e
        Rails.logger.error("[FiscaisController] Erro SIAFI: #{e.message}")
        render json: { error: "Erro ao consultar transferências" }, status: :internal_server_error
      end

      # GET /api/v1/fiscais/fnde/:cnpj
      def fnde
        cnpj = params[:cnpj]
        ano = params[:ano]&.to_i

        resultado = FndeService.consultar_liberacoes(cnpj, ano: ano)
        render json: resultado, status: :ok
      rescue StandardError => e
        Rails.logger.error("[FiscaisController] Erro FNDE: #{e.message}")
        render json: { error: "Erro ao consultar FNDE" }, status: :internal_server_error
      end

      # GET /api/v1/fiscais/completo/:cnpj
      # Consulta todas as fontes fiscais em paralelo
      def completo
        cnpj = params[:cnpj]
        codigo_ibge = params[:codigo_ibge]
        ano = params[:ano]&.to_i

        resultados = {}
        threads = []

        threads << Thread.new { resultados[:cauc] = CaucService.consultar(cnpj) }
        threads << Thread.new { resultados[:transferencias] = SiafiService.consultar_transferencias(cnpj, ano: ano) }
        threads << Thread.new { resultados[:fnde] = FndeService.consultar_liberacoes(cnpj, ano: ano) }
        threads << Thread.new { resultados[:sancoes] = PortalTransparenciaService.consultar_sancoes(cnpj) }

        if codigo_ibge.present?
          threads << Thread.new { resultados[:siconfi] = SiconfiService.consultar_por_ente(codigo_ibge, exercicio: ano) }
        end

        threads.each(&:join)

        render json: {
          cnpj: cnpj,
          codigo_ibge: codigo_ibge,
          **resultados,
          data_consulta: Time.current.iso8601
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[FiscaisController] Erro completo: #{e.message}")
        render json: { error: "Erro ao consultar dados fiscais" }, status: :internal_server_error
      end
    end
  end
end
