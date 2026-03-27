# frozen_string_literal: true

# FndeService
# Consulta recursos do FNDE (Fundo Nacional de Desenvolvimento da Educação)
# Dados de programas: FUNDEB, PNAE, PDDE, PNATE, etc.
class FndeService
  BASE_URL = "https://api.portaldatransparencia.gov.br/api-de-dados"

  PROGRAMAS_EDUCACIONAIS = %w[FUNDEB PNAE PDDE PNATE].freeze

  # Consulta liberações FNDE por CNPJ do município/ente
  # @param cnpj [String] CNPJ do ente favorecido
  # @param ano [Integer] Ano de exercício
  # @return [Hash] { liberacoes: Array, total: Integer, valor_total: Float }
  def self.consultar_liberacoes(cnpj, ano: nil)
    documento = cnpj.gsub(/\D/, "")
    ano ||= Time.current.year
    Rails.logger.info("[FNDE] Consultando liberações: #{documento}, ano #{ano}")

    api_key = ENV.fetch("PORTAL_TRANSPARENCIA_API_KEY", nil)
    return { liberacoes: [], total: 0, error: "API key não configurada" } if api_key.nil?

    # Consulta transferências filtradas por FNDE como órgão superior
    uri = URI("#{BASE_URL}/transferencias?cpfCnpjFavorecido=#{documento}&ano=#{ano}&codigoOrgao=26298&pagina=1")
    request = Net::HTTP::Get.new(uri)
    request["chave-api-dados"] = api_key
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 20
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      liberacoes = JSON.parse(response.body)
      liberacoes = liberacoes.is_a?(Array) ? liberacoes : []
      valor_total = liberacoes.sum { |l| l["valor"].to_f }

      {
        liberacoes: liberacoes,
        total: liberacoes.length,
        valor_total: valor_total,
        ano: ano,
        data_consulta: Time.current.iso8601
      }
    else
      Rails.logger.error("[FNDE] Erro #{response.code}: #{response.body}")
      { liberacoes: [], total: 0, error: "Serviço indisponível" }
    end
  rescue StandardError => e
    Rails.logger.error("[FNDE] Exceção: #{e.message}")
    { liberacoes: [], total: 0, error: e.message }
  end
end
