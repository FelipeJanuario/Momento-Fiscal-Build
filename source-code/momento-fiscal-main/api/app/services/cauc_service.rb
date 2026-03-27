# frozen_string_literal: true

# CaucService
# Consulta pendências no CAUC (Cadastro Único de Convênios)
# Aplica-se a entes públicos (municípios/estados)
# API via Transferegov.br / Plataforma +Brasil
class CaucService
  BASE_URL = ENV.fetch("CAUC_API_URL", "https://api.transferegov.sistema.gov.br/cauc")

  # Consulta pendências CAUC por CNPJ do ente público
  # @param cnpj [String] CNPJ da prefeitura/governo estadual
  # @return [Hash] { pendencias: Array, total: Integer, adimplente: Boolean }
  def self.consultar(cnpj)
    documento = cnpj.gsub(/\D/, "")
    Rails.logger.info("[CAUC] Consultando: #{documento}")

    uri = URI("#{BASE_URL}/#{documento}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 15
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      body = JSON.parse(response.body)
      pendencias = body["pendencias"] || body["itens"] || []
      {
        pendencias: pendencias,
        total: pendencias.length,
        adimplente: pendencias.empty?,
        data_consulta: Time.current.iso8601
      }
    when Net::HTTPNotFound
      { pendencias: [], total: 0, adimplente: true, data_consulta: Time.current.iso8601 }
    else
      Rails.logger.error("[CAUC] Erro #{response.code}: #{response.body}")
      { pendencias: [], total: 0, error: "Serviço indisponível" }
    end
  rescue StandardError => e
    Rails.logger.error("[CAUC] Exceção: #{e.message}")
    { pendencias: [], total: 0, error: e.message }
  end
end
