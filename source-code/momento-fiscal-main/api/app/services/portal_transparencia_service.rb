# frozen_string_literal: true

# PortalTransparenciaService
# Consulta cadastros de sanções do Portal da Transparência do Governo Federal
# API: https://api.portaldatransparencia.gov.br/api-de-dados/
# Requer chave de API gratuita (cadastro em dados.gov.br)
class PortalTransparenciaService
  BASE_URL = "https://api.portaldatransparencia.gov.br/api-de-dados"

  CADASTROS = {
    "CEIS" => "/ceis",                   # Empresas Inidôneas e Suspensas
    "CNEP" => "/cnep",                   # Empresas Punidas
    "CEPIM" => "/cepim",                 # Entidades Privadas Impedidas
    "CEAF" => "/ceaf"                    # Expulsões da Administração Federal
  }.freeze

  # Consulta todos os cadastros de sanções por CPF/CNPJ
  # @param cpf_cnpj [String] CPF ou CNPJ
  # @return [Hash] { sancoes: Array, total: Integer, from_cache: Boolean }
  def self.consultar_sancoes(cpf_cnpj)
    documento = cpf_cnpj.gsub(/\D/, "")

    # Verifica cache válido
    caches = SancaoCache.por_documento(documento).validos
    if caches.count == CADASTROS.size
      Rails.logger.info("[Transparencia] Usando cache válido: #{documento}")
      sancoes = caches.flat_map { |c| c.dados || [] }
      return { sancoes: sancoes, total: sancoes.length, from_cache: true }
    end

    # Consulta cada cadastro
    Rails.logger.info("[Transparencia] Consultando Portal da Transparência: #{documento}")
    todas_sancoes = []

    CADASTROS.each do |tipo, endpoint|
      sancoes = consultar_cadastro(endpoint, documento)
      salvar_cache(documento, tipo, sancoes)
      todas_sancoes.concat(sancoes)
    end

    { sancoes: todas_sancoes, total: todas_sancoes.length, from_cache: false }
  end

  # Consulta um cadastro específico
  # @param endpoint [String] Path do cadastro (ex: "/ceis")
  # @param documento [String] CPF/CNPJ limpo
  # @return [Array] Lista de sanções
  def self.consultar_cadastro(endpoint, documento)
    api_key = ENV.fetch("PORTAL_TRANSPARENCIA_API_KEY", nil)
    return [] if api_key.nil?

    param_key = documento.length <= 11 ? "cpfSancionado" : "cnpjSancionado"
    uri = URI("#{BASE_URL}#{endpoint}?#{param_key}=#{documento}&pagina=1")
    request = Net::HTTP::Get.new(uri)
    request["chave-api-dados"] = api_key
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 15
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      Rails.logger.error("[Transparencia] Erro #{endpoint}: #{response.code}")
      []
    end
  rescue StandardError => e
    Rails.logger.error("[Transparencia] Exceção #{endpoint}: #{e.message}")
    []
  end

  class << self
    private

    def salvar_cache(documento, tipo, dados)
      cache = SancaoCache.find_or_initialize_by(
        cpf_cnpj: documento.rjust(14, "0"),
        tipo_cadastro: tipo
      )
      cache.dados = dados
      cache.checked_at = Time.current
      cache.save
    rescue StandardError => e
      Rails.logger.error("[Transparencia] Erro ao salvar cache #{tipo}: #{e.message}")
    end
  end
end
