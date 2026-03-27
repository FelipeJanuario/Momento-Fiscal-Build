# frozen_string_literal: true

# SiconfiService
# Consulta dados fiscais no SICONFI (Sistema de Informações Contábeis e Fiscais)
# API pública do Tesouro Nacional: https://apidatalake.tesouro.gov.br/ords/siconfi/
class SiconfiService
  BASE_URL = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt"

  # Consulta dados fiscais do ente por código IBGE
  # @param codigo_ibge [String] Código IBGE do município (7 dígitos)
  # @param exercicio [Integer] Ano de exercício (default: ano atual)
  # @return [Hash] { rreo: Array, rgf: Array, dca: Array }
  def self.consultar_por_ente(codigo_ibge, exercicio: nil)
    exercicio ||= Time.current.year - 1
    Rails.logger.info("[SICONFI] Consultando ente #{codigo_ibge}, exercício #{exercicio}")

    rreo = consultar_rreo(codigo_ibge, exercicio)
    rgf = consultar_rgf(codigo_ibge, exercicio)

    {
      codigo_ibge: codigo_ibge,
      exercicio: exercicio,
      rreo: rreo,
      rgf: rgf,
      data_consulta: Time.current.iso8601
    }
  end

  # RREO - Relatório Resumido da Execução Orçamentária
  def self.consultar_rreo(codigo_ibge, exercicio)
    fetch_endpoint("/rreo", an_exercicio: exercicio, id_ente: codigo_ibge)
  end

  # RGF - Relatório de Gestão Fiscal
  def self.consultar_rgf(codigo_ibge, exercicio)
    fetch_endpoint("/rgf", an_exercicio: exercicio, id_ente: codigo_ibge)
  end

  # Busca lista de entes cadastrados
  def self.listar_entes(uf: nil)
    params = {}
    params[:sg_uf] = uf.upcase if uf
    fetch_endpoint("/entes", **params)
  end

  class << self
    private

    def fetch_endpoint(path, **params)
      query = params.map { |k, v| "#{k}=#{v}" }.join("&")
      uri = URI("#{BASE_URL}#{path}?#{query}")
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.open_timeout = 10
        http.read_timeout = 30
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        body = JSON.parse(response.body)
        body["items"] || body
      else
        Rails.logger.error("[SICONFI] Erro #{path}: #{response.code}")
        []
      end
    rescue StandardError => e
      Rails.logger.error("[SICONFI] Exceção #{path}: #{e.message}")
      []
    end
  end
end
