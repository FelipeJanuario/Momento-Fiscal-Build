# frozen_string_literal: true

# DatajudService - API Pública do Datajud (CNJ)
# Consulta processos judiciais em TODOS os tribunais do Brasil
# Documentação: https://datajud-wiki.cnj.jus.br/api-publica/endpoints
class JusbrasilService
  BASE_URL = "https://api-publica.datajud.cnj.jus.br"
  API_KEY = ENV.fetch("DATAJUD_API_KEY", "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw==")

  # Lista de todos os tribunais (aliases)
  TRIBUNAIS = {
    # Tribunais Superiores
    tst: "Tribunal Superior do Trabalho",
    tse: "Tribunal Superior Eleitoral",
    stj: "Superior Tribunal de Justiça",
    stm: "Superior Tribunal Militar",
    # Justiça Federal
    trf1: "TRF 1ª Região", trf2: "TRF 2ª Região", trf3: "TRF 3ª Região",
    trf4: "TRF 4ª Região", trf5: "TRF 5ª Região", trf6: "TRF 6ª Região",
    # Justiça Estadual
    tjac: "TJ Acre", tjal: "TJ Alagoas", tjam: "TJ Amazonas", tjap: "TJ Amapá",
    tjba: "TJ Bahia", tjce: "TJ Ceará", tjdft: "TJ DF", tjes: "TJ Espírito Santo",
    tjgo: "TJ Goiás", tjma: "TJ Maranhão", tjmg: "TJ Minas Gerais", tjms: "TJ MS",
    tjmt: "TJ Mato Grosso", tjpa: "TJ Pará", tjpb: "TJ Paraíba", tjpe: "TJ Pernambuco",
    tjpi: "TJ Piauí", tjpr: "TJ Paraná", tjrj: "TJ Rio de Janeiro", tjrn: "TJ RN",
    tjro: "TJ Rondônia", tjrr: "TJ Roraima", tjrs: "TJ Rio Grande do Sul",
    tjsc: "TJ Santa Catarina", tjse: "TJ Sergipe", tjsp: "TJ São Paulo", tjto: "TJ Tocantins",
    # Justiça do Trabalho
    trt1: "TRT 1ª Região", trt2: "TRT 2ª Região", trt3: "TRT 3ª Região",
    trt4: "TRT 4ª Região", trt5: "TRT 5ª Região", trt6: "TRT 6ª Região",
    trt7: "TRT 7ª Região", trt8: "TRT 8ª Região", trt9: "TRT 9ª Região",
    trt10: "TRT 10ª Região", trt11: "TRT 11ª Região", trt12: "TRT 12ª Região",
    trt13: "TRT 13ª Região", trt14: "TRT 14ª Região", trt15: "TRT 15ª Região",
    trt16: "TRT 16ª Região", trt17: "TRT 17ª Região", trt18: "TRT 18ª Região",
    trt19: "TRT 19ª Região", trt20: "TRT 20ª Região", trt21: "TRT 21ª Região",
    trt22: "TRT 22ª Região", trt23: "TRT 23ª Região", trt24: "TRT 24ª Região",
    # Justiça Eleitoral
    "tre-ac": "TRE Acre", "tre-al": "TRE Alagoas", "tre-am": "TRE Amazonas",
    "tre-ap": "TRE Amapá", "tre-ba": "TRE Bahia", "tre-ce": "TRE Ceará",
    "tre-dft": "TRE DF", "tre-es": "TRE Espírito Santo", "tre-go": "TRE Goiás",
    "tre-ma": "TRE Maranhão", "tre-mg": "TRE Minas Gerais", "tre-ms": "TRE MS",
    "tre-mt": "TRE Mato Grosso", "tre-pa": "TRE Pará", "tre-pb": "TRE Paraíba",
    "tre-pe": "TRE Pernambuco", "tre-pi": "TRE Piauí", "tre-pr": "TRE Paraná",
    "tre-rj": "TRE Rio de Janeiro", "tre-rn": "TRE RN", "tre-ro": "TRE Rondônia",
    "tre-rr": "TRE Roraima", "tre-rs": "TRE Rio Grande do Sul", "tre-sc": "TRE SC",
    "tre-se": "TRE Sergipe", "tre-sp": "TRE São Paulo", "tre-to": "TRE Tocantins",
    # Justiça Militar Estadual
    tjmmg: "TJM Minas Gerais", tjmrs: "TJM Rio Grande do Sul", tjmsp: "TJM São Paulo"
  }.freeze

  # Tribunais mais relevantes para consulta rápida (80% dos casos)
  TRIBUNAIS_PRIORITARIOS = %i[
    tjsp tjrj tjmg tjrs tjpr tjba tjpe tjce tjgo tjdf
    trf1 trf2 trf3 trf4 trf5
    trt1 trt2 trt3 trt4 trt15
    stj
  ].freeze

  # Busca processos por CPF/CNPJ
  # Tenta PJE primeiro (mais completo), depois Datajud como fallback
  def self.fetch_processes(cpf_cnpj, options = {})
    # Tenta consultar via PJE (retorna dados das partes)
    pje_result = PjeProcessosService.fetch_processes_by_cpf(cpf_cnpj, options)
    
    if pje_result[:status] == :success && pje_result[:total].positive?
      Rails.logger.info { "[JusbrasilService] Encontrados #{pje_result[:total]} processos via PJE" }
      return { source: "pje", **pje_result }
    end
    
    # Fallback: Datajud não suporta busca por CPF (apenas por número de processo)
    Rails.logger.warn { "[JusbrasilService] PJE falhou, Datajud não suporta busca por CPF/CNPJ" }
    {
      source: "none",
      status: :not_found,
      message: "API de consulta por CPF indisponível. Use número do processo.",
      total: 0,
      processos: []
    }
  end

  # Busca processos por número em TODOS os tribunais Datajud (paralelo)
  def self.fetch_by_numero(numero_processo, options = {})
    tribunais = options[:tribunais] || TRIBUNAIS.keys
    max_threads = options[:max_threads] || 10
    timeout = options[:timeout] || 15

    Rails.logger.info { "[Datajud] Buscando processo #{numero_processo} em #{tribunais.size} tribunais" }

    results = { status: :success, total: 0, processos: [], tribunais_consultados: [], erros: [] }
    mutex = Mutex.new

    # Divide tribunais em lotes para controlar threads
    tribunais.each_slice(max_threads) do |batch|
      threads = batch.map do |tribunal|
        Thread.new do
          begin
            response = search_by_numero(tribunal, numero_processo, timeout)
            mutex.synchronize do
              results[:tribunais_consultados] << tribunal.to_s
              if response[:status] == :success && response[:total].positive?
                results[:total] += response[:total]
                results[:processos].concat(response[:processos])
              end
            end
          rescue StandardError => e
            mutex.synchronize do
              results[:erros] << { tribunal: tribunal.to_s, error: e.message }
            end
          end
        end
      end
      threads.each(&:join)
    end

    Rails.logger.info { "[Datajud] Encontrados #{results[:total]} processos em #{results[:tribunais_consultados].size} tribunais" }
    results
  end

  # Busca rápida apenas nos tribunais prioritários
  def self.fetch_processes_fast(cpf_cnpj, options = {})
    fetch_processes(cpf_cnpj, options.merge(tribunais: TRIBUNAIS_PRIORITARIOS))
  end

  # Busca processos por número de processo em um tribunal específico
  def self.search_by_numero(tribunal, numero_processo, timeout = 15)
    alias_tribunal = "api_publica_#{tribunal}"
    url = "#{BASE_URL}/#{alias_tribunal}/_search"

    query = build_query_numero(numero_processo)
    response = perform_request(url, query, timeout)
    parse_response(response, tribunal)
  rescue StandardError => e
    Rails.logger.error { "[Datajud][#{tribunal}] Erro: #{e.message}" }
    { status: :error, tribunal: tribunal.to_s, error: e.message, total: 0, processos: [] }
  end

  private_class_method def self.build_query_numero(numero_processo)
    # Remove formatação do número do processo
    numero = numero_processo.to_s.gsub(/\D/, "")

    {
      query: {
        match: {
          numeroProcesso: numero
        }
      },
      size: 10,
      _source: %w[
        numeroProcesso classe tribunal dataAjuizamento
        dataHoraUltimaAtualizacao grau nivelSigilo
        orgaoJulgador assuntos movimentos
      ]
    }
  end

  private_class_method def self.perform_request(url, query, timeout)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = timeout
    http.open_timeout = 5

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "APIKey #{API_KEY}"
    request["Content-Type"] = "application/json"
    request.body = query.to_json

    http.request(request)
  end

  private_class_method def self.parse_response(response, tribunal)
    case response
    when Net::HTTPSuccess
      data = JSON.parse(response.body)
      hits = data.dig("hits", "hits") || []
      total = data.dig("hits", "total", "value") || 0

      processos = hits.map do |hit|
        source = hit["_source"]
        {
          id: hit["_id"],
          numero_processo: source["numeroProcesso"],
          tribunal: source["tribunal"] || tribunal.to_s.upcase,
          classe: source.dig("classe", "nome"),
          classe_codigo: source.dig("classe", "codigo"),
          grau: source["grau"],
          data_ajuizamento: source["dataAjuizamento"],
          ultima_atualizacao: source["dataHoraUltimaAtualizacao"],
          orgao_julgador: source.dig("orgaoJulgador", "nome"),
          assuntos: (source["assuntos"] || []).map { |a| a["nome"] },
          sigilo: source["nivelSigilo"]
        }
      end

      { status: :success, tribunal: tribunal.to_s, total: total, processos: processos }
    when Net::HTTPUnauthorized
      Rails.logger.error { "[Datajud][#{tribunal}] API Key inválida ou expirada" }
      { status: :unauthorized, tribunal: tribunal.to_s, total: 0, processos: [] }
    when Net::HTTPNotFound
      { status: :not_found, tribunal: tribunal.to_s, total: 0, processos: [] }
    else
      Rails.logger.error { "[Datajud][#{tribunal}] HTTP #{response.code}: #{response.body}" }
      { status: :error, tribunal: tribunal.to_s, total: 0, processos: [] }
    end
  rescue JSON::ParserError => e
    Rails.logger.error { "[Datajud][#{tribunal}] JSON inválido: #{e.message}" }
    { status: :error, tribunal: tribunal.to_s, total: 0, processos: [] }
  end
end
