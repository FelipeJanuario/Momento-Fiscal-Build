# frozen_string_literal: true

module Api
  module V1
    # Controller local para substituir Biddings Analyser
    # Retorna dados de empresas/estabelecimentos do banco + dívidas do Serpro
    class CompaniesController < ApplicationController
      # GET /api/v1/companies?cnpj=60.872.173/0001-21
      # Retorna empresa com dados de dívidas (cache ou Serpro)
      def index
        cnpj = params[:cnpj]
        
        if cnpj.blank?
          return render json: { error: "CNPJ é obrigatório" }, status: :bad_request
        end

        cnpj_limpo = cnpj.gsub(/\D/, "")
        
        # Busca estabelecimento no banco
        estabelecimento = Estabelecimento.includes(:empresa).find_by(cnpj_completo: cnpj_limpo)
        
        unless estabelecimento
          return render json: { 
            companies: [],
            message: "CNPJ não encontrado no banco de dados"
          }, status: :not_found
        end

        # Busca ou atualiza dívidas (com cache inteligente)
        dividas_resultado = SerproDividaAtivaService.fetch_and_update(cnpj_limpo)
        
        # Monta resposta no formato esperado pelo mobile
        company_data = {
          id: estabelecimento.id.to_s,
          cnpj: format_cnpj(cnpj_limpo),
          corporate_name: estabelecimento.empresa&.razao_social || "N/A",
          fantasy_name: estabelecimento.nome_fantasia || estabelecimento.empresa&.razao_social,
          activity_start_date: estabelecimento.data_inicio_atividade,
          cadastral_status: status_cadastral_texto(estabelecimento.situacao_cadastral),
          cadastral_status_date: estabelecimento.data_situacao_cadastral,
          email: estabelecimento.email,
          main_cnae: estabelecimento.cnae_fiscal_principal,
          social_capital: estabelecimento.empresa&.capital_social,
          uf: estabelecimento.uf,
          
          # Dívidas - sempre atualizadas
          debts_value: dividas_resultado[:debt_value],
          debts_count: dividas_resultado[:debt_count],
          debt_checked_at: estabelecimento.debt_checked_at,
          debt_from_cache: dividas_resultado[:from_cache],
          
          # Endereço
          address: {
            street: [estabelecimento.tipo_logradouro, estabelecimento.logradouro].compact.join(' '),
            number: estabelecimento.numero,
            complement: estabelecimento.complemento,
            neighborhood: estabelecimento.bairro,
            city: estabelecimento.municipio,
            state: estabelecimento.uf,
            zip_code: format_cep(estabelecimento.cep),
            geographic_coordinate: build_coordinate(estabelecimento)
          },
          
          # Coordenadas (se geocodificado)
          latitude: estabelecimento.latitude&.to_f,
          longitude: estabelecimento.longitude&.to_f,
          
          # Metadados
          matrix: estabelecimento.identificador_matriz_filial == 1,
          branch: estabelecimento.identificador_matriz_filial == 2,
          updated_at: estabelecimento.updated_at
        }
        
        render json: { 
          companies: [company_data],
          total_count: 1
        }, status: :ok
        
      rescue StandardError => e
        Rails.logger.error("[CompaniesController] Erro: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
        render json: { error: "Erro ao buscar dados da empresa" }, status: :internal_server_error
      end

      private

      def format_cnpj(cnpj)
        return cnpj if cnpj.length != 14
        "#{cnpj[0..1]}.#{cnpj[2..4]}.#{cnpj[5..7]}/#{cnpj[8..11]}-#{cnpj[12..13]}"
      end

      def format_cep(cep)
        return cep if cep.blank? || cep.length != 8
        "#{cep[0..4]}-#{cep[5..7]}"
      end

      def status_cadastral_texto(codigo)
        case codigo
        when 1 then "NULA"
        when 2 then "ATIVA"
        when 3 then "SUSPENSA"
        when 4 then "INAPTA"
        when 8 then "BAIXADA"
        else "DESCONHECIDA"
        end
      end

      def build_coordinate(estabelecimento)
        return nil unless estabelecimento.latitude && estabelecimento.longitude
        
        {
          type: "Point",
          coordinates: [estabelecimento.longitude.to_f, estabelecimento.latitude.to_f]
        }
      end
    end
  end
end
