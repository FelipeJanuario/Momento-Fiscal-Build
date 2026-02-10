class Api::V1::DebtorsController < ApplicationController
  # Endpoint público - não requer autenticação (dados públicos da Receita Federal)
  skip_before_action :authenticate_user!, only: [:nearby, :nearby_cep, :update_coordinates, :details, :batch_debts]
  
  # GET /api/v1/debtors/nearby_cep
  # Retorna estabelecimentos por prefixo de CEP (busca por região geográfica)
  #
  # Params:
  #   - cep: CEP completo ou parcial (mínimo 3 dígitos)
  #   - digits: quantidade de dígitos para match (padrão: 3)
  #   - page: número da página (padrão: 1)
  #   - page_size: itens por página (padrão: 50)
  #
  def nearby_cep
    cep = params[:cep]&.gsub(/\D/, '') # Remove não-dígitos
    digits = (params[:digits] || 3).to_i.clamp(2, 5)
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 50).to_i.clamp(1, 100)
    
    if cep.blank? || cep.length < digits
      render json: { error: "CEP deve ter pelo menos #{digits} dígitos" }, status: :bad_request
      return
    end
    
    # Prefixo para busca
    cep_prefix = cep[0, digits]
    
    # Busca estabelecimentos ativos com CEP na região
    estabelecimentos = Estabelecimento
      .ativas
      .where('cep LIKE ?', "#{cep_prefix}%")
      .includes(:empresa)
    
    # Paginação
    total_count = estabelecimentos.count
    total_pages = (total_count.to_f / page_size).ceil
    
    estabelecimentos = estabelecimentos
      .order(:nome_fantasia, :cnpj_completo)
      .offset((page - 1) * page_size)
      .limit(page_size)
    
    # Serializa resposta
    companies = estabelecimentos.map do |est|
      {
        id: est.id.to_s,
        cnpj: est.cnpj_completo,
        corporate_name: est.empresa&.razao_social || 'N/A',
        fantasy_name: est.nome_fantasia || est.empresa&.razao_social,
        address: {
          street: [est.tipo_logradouro, est.logradouro].compact.join(' '),
          number: est.numero,
          complement: est.complemento,
          neighborhood: est.bairro,
          city: est.municipio,
          state: est.uf,
          zip_code: format_cep(est.cep)
        },
        latitude: est.latitude,
        longitude: est.longitude,
        debts_value: est.debt_value&.to_f || 0,
        debts_count: est.debt_count || 0
      }
    end
    
    render json: {
      companies: companies,
      total_count: total_count,
      current_page: page,
      total_pages: total_pages,
      cep_prefix: cep_prefix,
      digits_used: digits
    }
  end

  # GET /api/v1/debtors/nearby
  # Retorna estabelecimentos geocodificados em um raio
  #
  # Params:
  #   - lat: latitude do centro
  #   - lng: longitude do centro
  #   - radius_km: raio em quilômetros (padrão: 5)
  #   - page: número da página (padrão: 1)
  #   - page_size: itens por página (padrão: 50)
  #
  # Response:
  # {
  #   "companies": [
  #     {
  #       "id": "1",
  #       "cnpj": "12345678000190",
  #       "corporate_name": "Empresa XYZ Ltda",
  #       "fantasy_name": "XYZ",
  #       "address": {
  #         "street": "Rua ABC",
  #         "number": "123",
  #         "neighborhood": "Centro",
  #         "city": "São Caetano do Sul",
  #         "state": "SP",
  #         "zip_code": "09510-200"
  #       },
  #       "latitude": -23.627049,
  #       "longitude": -46.570038,
  #       "distance_km": 1.5
  #     }
  #   ],
  #   "total_count": 150,
  #   "current_page": 1,
  #   "total_pages": 3
  # }
  def nearby
    # Valida parâmetros
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f
    radius_km = (params[:radius_km] || 5).to_f
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 50).to_i
    
    if lat.nil? || lng.nil?
      render json: { error: 'Parâmetros lat e lng são obrigatórios' }, status: :bad_request
      return
    end
    
    # Busca estabelecimentos na região usando bounding box
    # Cálculo aproximado: 1° latitude ≈ 111km
    # 1° longitude ≈ 111km * cos(latitude)
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * Math.cos(lat * Math::PI / 180.0))
    
    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lng = lng - lng_delta
    max_lng = lng + lng_delta
    
    # Query simples com bounding box (sem cálculo de distância no SQL)
    estabelecimentos = Estabelecimento
      .ativas
      .geocodificadas
      .where('latitude BETWEEN ? AND ?', min_lat, max_lat)
      .where('longitude BETWEEN ? AND ?', min_lng, max_lng)
      .includes(:empresa)
    
    # Paginação
    total_count = estabelecimentos.count
    total_pages = (total_count.to_f / page_size).ceil
    
    estabelecimentos = estabelecimentos
      .offset((page - 1) * page_size)
      .limit(page_size)
    
    # Serializa resposta (calcula distância em Ruby)
    companies = estabelecimentos.map do |est|
      distance = haversine_distance(lat, lng, est.latitude.to_f, est.longitude.to_f)
      {
        id: est.id.to_s,
        cnpj: est.cnpj_completo,
        corporate_name: est.empresa&.razao_social || 'N/A',
        fantasy_name: est.nome_fantasia || est.empresa&.razao_social,
        address: {
          street: [est.tipo_logradouro, est.logradouro].compact.join(' '),
          number: est.numero,
          complement: est.complemento,
          neighborhood: est.bairro,
          city: est.municipio,
          state: est.uf,
          zip_code: format_cep(est.cep),
          # Adiciona geographic_coordinate para compatibilidade com o modelo Flutter
          geographic_coordinate: {
            type: "Point",
            coordinates: [est.longitude.to_f, est.latitude.to_f] # [lng, lat] - padrão GeoJSON
          }
        },
        latitude: est.latitude.to_f,
        longitude: est.longitude.to_f,
        distance_km: distance.round(2),
        debts_value: est.debt_value&.to_f || 0,
        debts_count: est.debt_count || 0
      }
    end.sort_by { |c| c[:distance_km] }
    
    render json: {
      companies: companies,
      total_count: total_count,
      current_page: page,
      total_pages: total_pages,
      radius_km: radius_km,
      center: { lat: lat, lng: lng }
    }
  end

  # PATCH /api/v1/debtors/:id/coordinates
  # Atualiza coordenadas de um estabelecimento (geocodificação feita no frontend)
  def update_coordinates
    estabelecimento = Estabelecimento.find(params[:id])
    
    lat = params[:latitude]&.to_f
    lng = params[:longitude]&.to_f
    
    if lat.nil? || lng.nil?
      render json: { error: 'Latitude e longitude são obrigatórias' }, status: :bad_request
      return
    end
    
    # Validação básica de coordenadas
    if lat < -90 || lat > 90 || lng < -180 || lng > 180
      render json: { error: 'Coordenadas inválidas' }, status: :bad_request
      return
    end
    
    if estabelecimento.update(latitude: lat, longitude: lng)
      render json: { 
        success: true,
        id: estabelecimento.id,
        latitude: estabelecimento.latitude,
        longitude: estabelecimento.longitude
      }
    else
      render json: { error: estabelecimento.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Estabelecimento não encontrado' }, status: :not_found
  end

  # GET /api/v1/debtors/:id/details
  # Retorna dados completos do estabelecimento + empresa + dívidas SERPRO
  # Usa cache: verifica banco antes de chamar SERPRO
  def details
    estabelecimento = Estabelecimento.includes(:empresa).find(params[:id])
    empresa = estabelecimento.empresa

    # Monta resposta com dados locais (instantâneo)
    response = {
      id: estabelecimento.id.to_s,
      cnpj: estabelecimento.cnpj_completo,
      # Dados do Estabelecimento
      fantasy_name: estabelecimento.nome_fantasia,
      situacao_cadastral: estabelecimento.situacao_cadastral,
      email: estabelecimento.email,
      telefone: estabelecimento.telefone_1,
      cnae_principal: estabelecimento.cnae_fiscal_principal,
      # Endereço
      address: {
        street: [estabelecimento.tipo_logradouro, estabelecimento.logradouro].compact.join(' '),
        number: estabelecimento.numero,
        complement: estabelecimento.complemento,
        neighborhood: estabelecimento.bairro,
        city: estabelecimento.municipio,
        state: estabelecimento.uf,
        zip_code: format_cep(estabelecimento.cep)
      },
      latitude: estabelecimento.latitude,
      longitude: estabelecimento.longitude,
      # Dados da Empresa (matriz)
      corporate_name: empresa&.razao_social,
      capital_social: empresa&.capital_social&.to_f,
      porte_empresa: traduz_porte(empresa&.porte_empresa),
      natureza_juridica: empresa&.natureza_juridica,
      # Cache de dívidas local (se existir)
      debts_value: estabelecimento.debt_value&.to_f || 0,
      debts_count: estabelecimento.debt_count || 0,
      debt_checked_at: estabelecimento.debt_checked_at,
      # Lista de dívidas detalhadas
      dividas: [],
      from_cache: false
    }

    # Prepara resposta final com campos extras para frontend
    response[:total_dividas] = 0
    response[:fonte_dados] = ''
    response[:data_consulta] = ''
    response[:empresa] = {
      capital_social: empresa&.capital_social&.to_f,
      porte_empresa: traduz_porte(empresa&.porte_empresa),
      natureza_juridica: empresa&.natureza_juridica
    }

    # Verifica cache de dívidas no banco
    cnpj_limpo = estabelecimento.cnpj_completo.gsub(/\D/, '')
    cache = DividasCache.find_by(cnpj: cnpj_limpo.rjust(14, '0'))

    if cache&.cache_valid?
      # Cache válido - usa dados do cache
      Rails.logger.info("[DebtorsController] Usando cache de dívidas para #{cnpj_limpo}")
      response[:debts_value] = cache.debt_value&.to_f || 0
      response[:debts_count] = cache.debt_count || 0
      response[:debt_checked_at] = cache.checked_at
      response[:from_cache] = true

      # Busca dívidas detalhadas da tabela dividas (se existir)
      dividas_db = Divida.where(cnpj: cnpj_limpo).order(valor_consolidado: :desc)
      response[:dividas] = dividas_db.map { |d| serialize_divida(d) }
      response[:total_dividas] = cache.debt_value&.to_f || 0
      response[:fonte_dados] = 'Cache'
      response[:data_consulta] = cache.checked_at&.strftime('%d/%m/%Y') || ''
    else
      # Cache inválido ou não existe - consulta SERPRO
      Rails.logger.info("[DebtorsController] Consultando SERPRO para #{cnpj_limpo}")
      begin
        resultado = SerproDividaAtivaService.fetch_and_update(cnpj_limpo)
        
        response[:debts_value] = resultado[:debt_value] || 0
        response[:debts_count] = resultado[:debt_count] || 0
        response[:from_cache] = resultado[:from_cache] || false
        response[:debt_checked_at] = Time.current

        # Salvar dívidas detalhadas no banco
        salvar_dividas_no_banco(cnpj_limpo, resultado[:debts])
        
        # Serializa dívidas para resposta
        response[:dividas] = (resultado[:debts] || []).map { |d| serialize_divida_serpro(d) }
        response[:total_dividas] = resultado[:debt_value] || 0
        response[:fonte_dados] = 'SERPRO'
        response[:data_consulta] = Time.current.strftime('%d/%m/%Y')

        # Atualiza cache no estabelecimento
        estabelecimento.update(
          debt_value: resultado[:debt_value],
          debt_count: resultado[:debt_count],
          debt_checked_at: Time.current
        )
      rescue StandardError => e
        Rails.logger.error("[DebtorsController] Erro ao consultar SERPRO: #{e.message}")
        # Retorna dados locais mesmo se SERPRO falhar
      end
    end

    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Estabelecimento não encontrado' }, status: :not_found
  end

  # POST /api/v1/debtors/batch_debts
  # Busca dívidas SERPRO para múltiplos CNPJs em paralelo
  # Usa cache agressivo: só consulta SERPRO se cache inválido (> 3 meses)
  #
  # Body:
  #   - cnpjs: Array de CNPJs (máximo 50)
  #
  # Response:
  # {
  #   "results": {
  #     "12345678000190": { "debt_value": 15000.50, "debt_count": 3, "from_cache": true },
  #     "98765432000110": { "debt_value": 0, "debt_count": 0, "from_cache": false }
  #   },
  #   "processed": 50,
  #   "cached": 45,
  #   "fetched": 5,
  #   "errors": 0
  # }
  def batch_debts
    cnpjs = params[:cnpjs]
    
    if cnpjs.blank? || !cnpjs.is_a?(Array)
      render json: { error: 'Parâmetro cnpjs (Array) é obrigatório' }, status: :bad_request
      return
    end

    # Limita a 50 CNPJs por requisição para evitar sobrecarga
    cnpjs = cnpjs.take(50).map { |c| c.to_s.gsub(/\D/, '').rjust(14, '0') }
    
    results = {}
    stats = { processed: 0, cached: 0, fetched: 0, errors: 0 }
    
    # Primeiro, busca todos os caches válidos de uma vez
    caches = DividasCache.where(cnpj: cnpjs).index_by(&:cnpj)
    
    # CNPJs que precisam consultar SERPRO (cache inválido ou inexistente)
    cnpjs_to_fetch = []
    
    cnpjs.each do |cnpj|
      cache = caches[cnpj]
      if cache&.cache_valid?
        results[cnpj] = {
          debt_value: cache.debt_value&.to_f || 0,
          debt_count: cache.debt_count || 0,
          from_cache: true,
          checked_at: cache.checked_at&.iso8601
        }
        stats[:cached] += 1
      else
        cnpjs_to_fetch << cnpj
      end
      stats[:processed] += 1
    end
    
    Rails.logger.info("[DebtorsController] batch_debts: #{stats[:cached]} do cache, #{cnpjs_to_fetch.length} para buscar no SERPRO")
    
    # Busca no SERPRO em paralelo (máximo 5 threads para não sobrecarregar)
    # Usa Parallel se disponível, senão processa sequencialmente
    if cnpjs_to_fetch.any?
      threads = []
      mutex = Mutex.new
      
      # Processa em lotes de 5 para controlar rate limiting
      cnpjs_to_fetch.each_slice(5) do |batch|
        batch.each do |cnpj|
          threads << Thread.new do
            begin
              resultado = SerproDividaAtivaService.fetch_and_update(cnpj)
              mutex.synchronize do
                results[cnpj] = {
                  debt_value: resultado[:debt_value] || 0,
                  debt_count: resultado[:debt_count] || 0,
                  from_cache: false,
                  checked_at: Time.current.iso8601
                }
                stats[:fetched] += 1
              end
            rescue StandardError => e
              Rails.logger.error("[DebtorsController] Erro ao buscar SERPRO para #{cnpj}: #{e.message}")
              mutex.synchronize do
                results[cnpj] = {
                  debt_value: 0,
                  debt_count: 0,
                  from_cache: false,
                  error: true
                }
                stats[:errors] += 1
              end
            end
          end
        end
        
        # Aguarda lote terminar antes de iniciar próximo (rate limiting)
        threads.each(&:join)
        threads.clear
        
        # Pequeno delay entre lotes para não sobrecarregar SERPRO
        sleep(0.2) if cnpjs_to_fetch.length > 5
      end
    end
    
    render json: {
      results: results,
      processed: stats[:processed],
      cached: stats[:cached],
      fetched: stats[:fetched],
      errors: stats[:errors]
    }
  end
  
  private
  
  # Calcula distância usando fórmula Haversine (em Ruby)
  def haversine_distance(lat1, lng1, lat2, lng2)
    rad_per_deg = Math::PI / 180
    earth_radius = 6371 # km
    
    dlat = (lat2 - lat1) * rad_per_deg
    dlng = (lng2 - lng1) * rad_per_deg
    
    a = Math.sin(dlat / 2)**2 + 
        Math.cos(lat1 * rad_per_deg) * Math.cos(lat2 * rad_per_deg) * 
        Math.sin(dlng / 2)**2
    
    2 * earth_radius * Math.asin(Math.sqrt(a))
  end
  
  def format_cep(cep)
    return nil unless cep
    "#{cep[0..4]}-#{cep[5..7]}"
  end

  # Traduz código de porte para descrição
  def traduz_porte(codigo)
    case codigo
    when 0 then 'Não informado'
    when 1 then 'Microempresa'
    when 3 then 'Empresa de Pequeno Porte'
    when 5 then 'Demais'
    else codigo.to_s
    end
  end

  # Serializa dívida do banco local
  def serialize_divida(divida)
    {
      numero_inscricao: divida.numero_inscricao,
      valor_consolidado: divida.valor_consolidado&.to_f,
      situacao: divida.situacao_inscricao,
      tipo_devedor: divida.tipo_devedor,
      data_inscricao: divida.data_inscricao,
      nome_devedor: divida.nome_devedor
    }
  end

  # Serializa dívida do retorno SERPRO
  def serialize_divida_serpro(divida)
    {
      numero_inscricao: divida['numeroInscricao'],
      valor_consolidado: parse_valor_moeda(divida['valorTotalConsolidadoMoeda']),
      situacao: divida['situacaoInscricao'],
      tipo_devedor: divida['tipoDevedor'],
      data_inscricao: divida['dataInscricao'],
      nome_devedor: divida['nomeDevedor']
    }
  end

  # Salva dívidas detalhadas no banco
  def salvar_dividas_no_banco(cnpj, dividas)
    return if dividas.blank?

    dividas.each do |d|
      Divida.find_or_initialize_by(
        cnpj: cnpj,
        numero_inscricao: d['numeroInscricao']
      ).tap do |divida|
        divida.valor_consolidado = parse_valor_moeda(d['valorTotalConsolidadoMoeda'])
        divida.situacao_inscricao = d['situacaoInscricao']
        divida.situacao_descricao = d['situacaoDescricao']
        divida.tipo_devedor = d['tipoDevedor']
        divida.nome_devedor = d['nomeDevedor']
        divida.tipo_regularidade = d['tipoRegularidade']
        divida.data_inscricao = d['dataInscricao']
        divida.save
      end
    end
  rescue StandardError => e
    Rails.logger.error("[DebtorsController] Erro ao salvar dívidas: #{e.message}")
  end

  # Converte string de valor moeda brasileiro para Float
  def parse_valor_moeda(valor_str)
    return 0.0 if valor_str.nil? || valor_str.to_s.empty?
    valor_str.to_s.gsub('.', '').gsub(',', '.').to_f
  end
end
