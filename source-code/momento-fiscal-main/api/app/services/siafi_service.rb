# frozen_string_literal: true

# SiafiService
# Consulta transferências federais via Portal da Transparência
# Endpoint: /transferencias (dados do SIAFI - Sistema Integrado de Administração Financeira)
class SiafiService
  BASE_URL = "https://api.portaldatransparencia.gov.br/api-de-dados"

  # Consulta transferências federais recebidas por CNPJ
  # @param cnpj [String] CNPJ do favorecido
  # @param ano [Integer] Ano de exercício (default: ano atual)
  # @return [Hash] { transferencias: Array, total: Integer, valor_total: Float }
  def self.consultar_transferencias(cnpj, ano: nil)
    documento = cnpj.gsub(/\D/, "")
    ano ||= Time.current.year
    Rails.logger.info("[SIAFI] Consultando transferências: #{documento}, ano #{ano}")

    api_key = ENV.fetch("PORTAL_TRANSPARENCIA_API_KEY", nil)
    return { transferencias: [], total: 0, error: "API key não configurada" } if api_key.nil?

    uri = URI("#{BASE_URL}/transferencias?cpfCnpjFavorecido=#{documento}&ano=#{ano}&pagina=1")
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
      transferencias = JSON.parse(response.body)
      transferencias = transferencias.is_a?(Array) ? transferencias : []
      valor_total = transferencias.sum { |t| t["valor"].to_f }

      {
        transferencias: transferencias,
        total: transferencias.length,
        valor_total: valor_total,
        ano: ano,
        data_consulta: Time.current.iso8601
      }
    else
      Rails.logger.error("[SIAFI] Erro #{response.code}: #{response.body}")
      { transferencias: [], total: 0, error: "Serviço indisponível" }
    end
  rescue StandardError => e
    Rails.logger.error("[SIAFI] Exceção: #{e.message}")
    { transferencias: [], total: 0, error: e.message }
  end
end
