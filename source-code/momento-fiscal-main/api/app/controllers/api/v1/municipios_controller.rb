# frozen_string_literal: true

module Api
  module V1
    # Controller para busca por município (dados fiscais consolidados)
    class MunicipiosController < ApplicationController
      # GET /api/v1/municipios/buscar?q=termo
      def buscar
        termo = params[:q]
        uf = params[:uf]

        if termo.blank? || termo.length < 2
          return render json: { error: "Termo de busca deve ter pelo menos 2 caracteres" }, status: :bad_request
        end

        municipios = Municipio.buscar_nome(termo)
        municipios = municipios.por_uf(uf) if uf.present?
        municipios = municipios.limit(20)

        render json: {
          municipios: municipios.as_json(only: %i[id codigo_ibge nome uf cnpj_prefeitura populacao latitude longitude]),
          total: municipios.length
        }, status: :ok
      end

      # GET /api/v1/municipios/:codigo_ibge/completo
      # Consulta completa de todas as fontes fiscais do município
      def completo
        codigo_ibge = params[:codigo_ibge]
        municipio = Municipio.find_by(codigo_ibge: codigo_ibge)

        if municipio.nil?
          return render json: { error: "Município não encontrado" }, status: :not_found
        end

        cnpj = municipio.cnpj_prefeitura
        ano = params[:ano]&.to_i

        resultados = { municipio: municipio.as_json(only: %i[codigo_ibge nome uf populacao]) }
        threads = []

        if cnpj.present?
          threads << Thread.new { resultados[:cauc] = CaucService.consultar(cnpj) }
          threads << Thread.new { resultados[:pgfn] = PgfnRegularizeService.fetch_and_update(cnpj) }
          threads << Thread.new { resultados[:sancoes] = PortalTransparenciaService.consultar_sancoes(cnpj) }
          threads << Thread.new { resultados[:transferencias] = SiafiService.consultar_transferencias(cnpj, ano: ano) }
          threads << Thread.new { resultados[:fnde] = FndeService.consultar_liberacoes(cnpj, ano: ano) }
        end

        threads << Thread.new { resultados[:siconfi] = SiconfiService.consultar_por_ente(codigo_ibge, exercicio: ano) }

        threads.each(&:join)

        render json: {
          **resultados,
          data_consulta: Time.current.iso8601
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[MunicipiosController] Erro: #{e.message}")
        render json: { error: "Erro ao consultar dados do município" }, status: :internal_server_error
      end
    end
  end
end
