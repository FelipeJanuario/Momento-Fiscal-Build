# frozen_string_literal: true

# Serviço para consultar processos no PJE usando Bearer Token
class PjeProcessosService
  # URL base pode variar por tribunal
  # Exemplo: https://pje-1g-trf1.jus.br/pje-legacy/api/v1/processos
  BASE_URL = ENV.fetch("PJE_API_URL", "https://pje-1g.tjdft.jus.br/pje-legacy/api/v1/processos")

  # Consulta processos por CPF/CNPJ
  # @param cpf_cnpj [String] CPF ou CNPJ sem formatação
  # @param options [Hash] Opções adicionais (fields, size, page)
  # @return [Hash] Resultado da consulta
  def self.fetch_processes_by_cpf(cpf_cnpj, options = {})
    documento = cpf_cnpj.to_s.gsub(/\D/, "")
    
    # Obter token JWT do PJE
    token = GetPjeTokenService.new.call
    
    # Construir filtro
    filter = "partes.cpf eq #{documento}"
    
    # Parâmetros da query
    params = {
      filter: filter,
      fields: options[:fields] || "numero,classe.nome,partes.nome,data-distribuicao,situacao",
      page: options.fetch(:page, 1),
      size: options.fetch(:size, 50)
    }
    
    Rails.logger.info("[PjeProcessosService] Consultando CPF #{documento}")
    
    response = perform_request(token, params)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("[PjeProcessosService] Erro: #{e.message}")
    { status: :error, message: e.message, processos: [] }
  end

  private_class_method def self.perform_request(token, params)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    
    http.request(request)
  end

  private_class_method def self.parse_response(response)
    case response
    when Net::HTTPSuccess
      data = JSON.parse(response.body)
      {
        status: :success,
        total: data.dig("page-info", "count") || data["result"]&.size || 0,
        processos: data["result"] || [],
        page_info: data["page-info"]
      }
    when Net::HTTPUnauthorized
      Rails.logger.error("[PjeProcessosService] Token inválido ou expirado")
      { status: :unauthorized, message: "Token inválido", processos: [] }
    when Net::HTTPNotFound
      { status: :not_found, message: "Nenhum processo encontrado", processos: [] }
    else
      Rails.logger.error("[PjeProcessosService] HTTP #{response.code}: #{response.body}")
      { status: :error, message: "Erro na consulta", processos: [] }
    end
  rescue JSON::ParserError => e
    Rails.logger.error("[PjeProcessosService] JSON inválido: #{e.message}")
    { status: :error, message: "Resposta inválida", processos: [] }
  end
end
