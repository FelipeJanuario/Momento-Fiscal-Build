# frozen_string_literal: true

# PgfnRegularizeService
# Consulta situação fiscal via API do Regularize/PGFN (complementar ao SERPRO)
# Documentação: https://www.regularize.pgfn.gov.br/
class PgfnRegularizeService
  BASE_URL = ENV.fetch("PGFN_REGULARIZE_URL", "https://consulta-cda.pgfn.gov.br/ConsultaCDA/rest/consultaCDA")

  # Consulta dívidas PGFN por CPF/CNPJ
  # @param cpf_cnpj [String] CPF ou CNPJ (com ou sem formatação)
  # @return [Hash] { debt_count: Integer, debt_value: Float, debts: Array, source: String }
  def self.fetch_and_update(cpf_cnpj)
    cnpj_limpo = cpf_cnpj.gsub(/\D/, "")

    # Verifica cache PGFN
    cache = DividasCache.pgfn.find_by(cnpj: cnpj_limpo.rjust(14, "0"))
    if cache&.cache_valid?
      Rails.logger.info("[PGFN] Usando cache válido: #{cnpj_limpo}")
      return {
        debt_count: cache.debt_count || 0,
        debt_value: cache.debt_value || 0.0,
        debts: fetch_dividas(cnpj_limpo),
        from_cache: true,
        source: "pgfn"
      }
    end

    Rails.logger.info("[PGFN] Consultando Regularize: #{cnpj_limpo}")
    dividas = fetch_dividas(cnpj_limpo)

    total_valor = dividas.sum { |d| d["valorConsolidado"].to_f }

    resultado = {
      debt_count: dividas.length,
      debt_value: total_valor,
      debts: dividas,
      from_cache: false,
      source: "pgfn"
    }

    atualizar_cache(cnpj_limpo, resultado)
    resultado
  end

  # Consulta direta à API PGFN
  # @param cpf_cnpj [String] CPF ou CNPJ limpo
  # @return [Array] Lista de inscrições em dívida ativa
  def self.fetch_dividas(cpf_cnpj)
    cnpj_limpo = cpf_cnpj.gsub(/\D/, "")
    uri = URI("#{BASE_URL}/#{cnpj_limpo}")
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
      # A API pode retornar diferentes formatos dependendo do endpoint
      body.is_a?(Array) ? body : (body["inscricoes"] || body["dividas"] || [])
    when Net::HTTPNotFound
      []
    else
      Rails.logger.error("[PGFN] Erro #{response.code}: #{response.body}")
      []
    end
  rescue StandardError => e
    Rails.logger.error("[PGFN] Exceção: #{e.message}")
    []
  end

  class << self
    private

    def atualizar_cache(cnpj, resultado)
      cnpj_formatado = cnpj.to_s.rjust(14, "0")
      cache = DividasCache.find_or_initialize_by(cnpj: cnpj_formatado, source: "pgfn")
      cache.debt_value = resultado[:debt_value].to_f
      cache.debt_count = resultado[:debt_count].to_i
      cache.checked_at = Time.current

      if cache.save
        Rails.logger.info("[PGFN] Cache salvo: #{cnpj_formatado}")
      else
        Rails.logger.error("[PGFN] Falha ao salvar cache: #{cache.errors.full_messages.join(', ')}")
      end
    rescue StandardError => e
      Rails.logger.error("[PGFN] Exceção ao salvar cache: #{e.message}")
    end
  end
end
