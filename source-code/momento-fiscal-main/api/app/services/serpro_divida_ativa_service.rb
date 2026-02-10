# frozen_string_literal: true

# SerproDividaAtivaService
# Serviço para consultar dívidas ativas na API do Serpro e atualizar o cache no estabelecimento
class SerproDividaAtivaService
  DIVIDA_ATIVA_URL = "https://gateway.apiserpro.serpro.gov.br/consulta-divida-ativa-df/api/v1/devedor"

  # Consulta dívidas com cache inteligente
  # 1. Verifica se tem cache válido no banco (< 3 meses)
  # 2. Se sim, retorna do cache
  # 3. Se não, consulta Serpro, salva no banco e retorna
  # @param cnpj [String] CNPJ ou CPF (com ou sem formatação)
  # @return [Hash] { debt_count: Integer, debt_value: Float, debts: Array, from_cache: Boolean }
  def self.fetch_and_update(cnpj)
    cnpj_limpo = cnpj.gsub(/\D/, "")
    
    # Verifica cache na tabela dividas_cache
    cache = DividasCache.find_by(cnpj: cnpj_limpo)
    
    if cache&.cache_valid?
      Rails.logger.info("[SerproDividaAtiva] Usando cache válido para totais: #{cnpj_limpo}")
      
      # Busca a lista completa do Serpro (sempre atualizada)
      Rails.logger.info("[SerproDividaAtiva] Buscando lista detalhada do Serpro...")
      dividas = fetch_dividas(cnpj_limpo)
      dividas_ativas = dividas.select { |d| d["tipoRegularidade"] == "IRREGULAR" }
      
      return {
        debt_count: cache.debt_count || 0,
        debt_value: cache.debt_value || 0.0,
        debts: dividas_ativas,
        from_cache: true
      }
    end
    
    # Cache inválido ou não existe - consulta Serpro
    Rails.logger.info("[SerproDividaAtiva] Consultando Serpro (cache inválido): #{cnpj_limpo}")
    dividas = fetch_dividas(cnpj_limpo)
    
    if dividas.empty?
      resultado = { debt_count: 0, debt_value: 0.0, debts: [], from_cache: false }
      atualizar_cache(cnpj_limpo, resultado)
      return resultado
    end
    
    # Calcula totais (apenas dívidas ativas/irregulares)
    dividas_ativas = dividas.select { |d| d["tipoRegularidade"] == "IRREGULAR" }
    
    total_valor = dividas_ativas.sum do |divida|
      parse_valor_moeda(divida["valorTotalConsolidadoMoeda"])
    end
    
    resultado = {
      debt_count: dividas_ativas.length,
      debt_value: total_valor,
      debts: dividas_ativas,
      from_cache: false
    }
    
    # Atualiza/cria cache
    atualizar_cache(cnpj_limpo, resultado)
    
    resultado
  end

  # Apenas consulta dívidas sem atualizar banco
  # @param cnpj [String] CNPJ ou CPF
  # @return [Array] Lista de dívidas
  def self.fetch_dividas(cnpj)
    cnpj_limpo = cnpj.gsub(/\D/, "")
    url = "#{DIVIDA_ATIVA_URL}/#{cnpj_limpo}"
    token = SerproAuthService.fetch_access_token

    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    when Net::HTTPNotFound
      []
    else
      Rails.logger.error("[SerproDividaAtiva] Erro #{response.code}: #{response.body}")
      []
    end
  rescue StandardError => e
    Rails.logger.error("[SerproDividaAtiva] Exceção: #{e.message}")
    []
  end

  private

  # Converte string de valor moeda brasileiro para Float
  # Ex: "1.234.567,89" -> 1234567.89
  def self.parse_valor_moeda(valor_str)
    return 0.0 if valor_str.nil? || valor_str.empty?
    
    # Remove pontos de milhar e substitui vírgula por ponto
    valor_str.to_s
             .gsub(".", "")
             .gsub(",", ".")
             .to_f
  end

  # Atualiza ou cria o cache de dívidas
  def self.atualizar_cache(cnpj, resultado)
    # Garante que o CNPJ tem exatamente 14 dígitos (pode ser CPF com 11)
    cnpj_formatado = cnpj.to_s.rjust(14, '0')
    
    # Garante valores numéricos para evitar falha de validação
    debt_count = resultado[:debt_count].to_i
    debt_value = resultado[:debt_value].to_f
    
    Rails.logger.info("[SerproDividaAtiva] 📝 Salvando cache para #{cnpj_formatado}: debt_count=#{debt_count}, debt_value=#{debt_value}")
    
    cache = DividasCache.find_or_initialize_by(cnpj: cnpj_formatado)
    
    cache.debt_value = debt_value
    cache.debt_count = debt_count
    cache.checked_at = Time.current
    
    if cache.save
      Rails.logger.info("[SerproDividaAtiva] ✅ Cache salvo com sucesso #{cnpj_formatado}: #{debt_count} dívidas, R$ #{debt_value}")
    else
      Rails.logger.error("[SerproDividaAtiva] ❌ Falha validação ao salvar cache: #{cache.errors.full_messages.join(', ')}")
    end
  rescue StandardError => e
    Rails.logger.error("[SerproDividaAtiva] ❌ Exceção ao salvar cache: #{e.class} - #{e.message}")
    Rails.logger.error("[SerproDividaAtiva] Backtrace: #{e.backtrace.first(5).join("\n")}")
  end
end
