# frozen_string_literal: true

module Api
  module V1
    # Controller to handle Biddings Analyser requests
    class BiddingsAnalyserController < ApplicationController
      # skip_authorize_resource  only: %i[download]
      # skip_authorization_check only: %i[download]
      # skip_before_action :authenticate_devise_model!, only: %i[download]

      def download
        # Endpoint descontinuado - Biddings Analyser não está mais disponível
        render json: { 
          error: "Download de arquivos não disponível",
          message: "Serviço externo descontinuado"
        }, status: :not_implemented
      end

      def companies
        # Endpoint local - usa dados do banco + Serpro
        if params[:cnpj].blank?
          return render json: { 
            error: "CNPJ é obrigatório",
            companies: []
          }, status: :bad_request
        end

        Rails.logger.info("[Companies] Buscando CNPJ: #{params[:cnpj]}")
        
        cnpj_limpo = params[:cnpj].gsub(/\D/, "")
        
        # Tenta buscar primeiro no banco de estabelecimentos (dados completos da Receita)
        estabelecimento = Estabelecimento.includes(:empresa).find_by(cnpj_completo: cnpj_limpo)
        
        # Busca ou atualiza dívidas do Serpro (com cache inteligente)
        dividas_resultado = SerproDividaAtivaService.fetch_and_update(cnpj_limpo)
        
        if estabelecimento
          # Tem dados completos da Receita Federal
          company_data = build_company_response(estabelecimento, dividas_resultado)
          
          render json: { 
            companies: [company_data],
            total_count: 1,
            source: "local_db"
          }.to_json, status: :ok
        else
          # Não tem no banco da Receita, mas pode ter consultado no Serpro
          # Busca no cache de dívidas
          cache = DividasCache.find_by(cnpj: cnpj_limpo)
          
          if cache
            # Monta resposta com dados básicos do cache
            company_data = {
              cnpj: cnpj_limpo,
              razao_social: "Empresa não cadastrada na Receita Federal",
              nome_fantasia: nil,
              debts_count: cache.debt_count,
              debts_value: cache.debt_value,
              debt_from_cache: dividas_resultado[:from_cache]
            }
            
            render json: { 
              companies: [company_data],
              total_count: 1,
              source: "serpro_cache",
              message: "Dados limitados - CNPJ não importado da Receita Federal"
            }.to_json, status: :ok
          else
            # Nem no banco da Receita nem conseguiu consultar Serpro
            render json: { 
              companies: [],
              message: "CNPJ não encontrado",
              source: "none"
            }, status: :not_found
          end
        end
      rescue StandardError => e
        Rails.logger.error("[Companies] Erro: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { 
          error: "Erro ao buscar dados da empresa",
          message: e.message,
          companies: []
        }, status: :internal_server_error
      end

      def debts
        # Retorna totais agregados do cache + lista detalhada do Serpro
        if params[:cpf_cnpj].blank?
          return render json: { error: "CPF/CNPJ é obrigatório" }, status: :bad_request
        end

        Rails.logger.info("[Debts] Consultando dívidas: #{params[:cpf_cnpj]}")
        
        cnpj_limpo = params[:cpf_cnpj].gsub(/\D/, "")
        
        # Busca ou atualiza cache (retorna totais agregados)
        dividas_resultado = SerproDividaAtivaService.fetch_and_update(cnpj_limpo)
        
        # Se a lista detalhada está no resultado, usa ela; senão retorna vazia
        debts_list = dividas_resultado[:debts] || []
        
        # Retorna no formato esperado pelo frontend
        render json: { 
          debts: debts_list,
          total_count: dividas_resultado[:debt_count],
          total_value: dividas_resultado[:debt_value],
          from_cache: dividas_resultado[:from_cache],
          source: "serpro"
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("[Debts] Erro: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { 
          error: "Erro ao consultar dívidas",
          debts: [],
          total_count: 0,
          total_value: 0
        }, status: :internal_server_error
      end

      def debts_per_debted_name
        # Endpoint não implementado localmente ainda
        render json: { 
          error: "Endpoint em desenvolvimento - use /api/v1/serpro/dividas/:cpf_cnpj",
          data: []
        }, status: :not_implemented
      end

      def count_companies_in_location
        # Usa dados locais geocodificados via ETL
        render json: { 
          error: "Use /api/v1/debtors/nearby para buscar empresas por localização",
          count: 0
        }, status: :not_implemented
      end

      def companies_in_location
        # Redireciona para endpoint local (dados geocodificados pelo ETL)
        render json: { 
          error: "Use /api/v1/debtors/nearby para buscar empresas próximas",
          companies: []
        }, status: :not_implemented
      end

      private

      def search_params
        params.permit(:q, :page, :page_size, :where)
      end

      def build_company_response(estabelecimento, dividas_resultado)
        {
          id: estabelecimento.id.to_s,
          cnpj: format_cnpj(estabelecimento.cnpj_completo),
          corporate_name: estabelecimento.empresa&.razao_social || "N/A",
          fantasy_name: estabelecimento.nome_fantasia || estabelecimento.empresa&.razao_social,
          activity_start_date: estabelecimento.data_inicio_atividade,
          cadastral_status: status_cadastral_texto(estabelecimento.situacao_cadastral),
          cadastral_status_date: estabelecimento.data_situacao_cadastral,
          email: estabelecimento.email,
          main_cnae: estabelecimento.cnae_fiscal_principal,
          social_capital: estabelecimento.empresa&.capital_social,
          uf: estabelecimento.uf,
          debts_value: dividas_resultado[:debt_value],
          debts_count: dividas_resultado[:debt_count],
          debt_checked_at: estabelecimento.debt_checked_at,
          debt_from_cache: dividas_resultado[:from_cache],
          address: {
            street: [estabelecimento.tipo_logradouro, estabelecimento.logradouro].compact.join(' '),
            number: estabelecimento.numero,
            complement: estabelecimento.complemento,
            neighborhood: estabelecimento.bairro,
            city: estabelecimento.municipio,
            state: estabelecimento.uf,
            zip_code: format_cep(estabelecimento.cep)
          },
          latitude: estabelecimento.latitude&.to_f,
          longitude: estabelecimento.longitude&.to_f,
          matrix: estabelecimento.identificador_matriz_filial == 1,
          branch: estabelecimento.identificador_matriz_filial == 2,
          updated_at: estabelecimento.updated_at
        }
      end

      def format_cnpj(cnpj)
        return cnpj if cnpj.blank? || cnpj.length != 14
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

      # Consulta SERPRO Dívida Ativa
      def render_serpro_debts(cpf_cnpj)
        cpf = cpf_cnpj.gsub(/\D/, "") # Remove formatação
        url = "https://gateway.apiserpro.serpro.gov.br/consulta-divida-ativa-df/api/v1/devedor/#{cpf}"
        token = SerproAuthService.fetch_access_token

        uri = URI(url)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{token}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          render json: { source: "serpro", data: JSON.parse(response.body) }, status: :ok
        when Net::HTTPNotFound
          render json: { source: "serpro", data: [], message: "Nenhuma dívida ativa encontrada" }, status: :ok
        else
          Rails.logger.error("[SERPRO] Erro ao consultar: #{response.code} - #{response.body}")
          render json: { error: "Serviço temporariamente indisponível" }, status: :service_unavailable
        end
      rescue StandardError => e
        Rails.logger.error("[SERPRO] Exceção: #{e.message}")
        render json: { error: "Erro ao consultar dívidas" }, status: :internal_server_error
      end

      def skippable_controller
        true
      end
    end
  end
end
