# frozen_string_literal: true

# Job para geocodificar estabelecimentos sem coordenadas
# Processa em lotes respeitando limites de APIs gratuitas
class GeocodeEstabelecimentosJob < ApplicationJob
  queue_as :default

  # Processa um lote de estabelecimentos sem coordenadas
  def perform(batch_size: 50)
    Rails.logger.info "[GeocodeJob] Iniciando processamento..."
    
    # Busca estabelecimentos sem coordenadas
    estabelecimentos = Estabelecimento
      .ativas
      .where(latitude: nil)
      .or(Estabelecimento.ativas.where(longitude: nil))
      .limit(batch_size)
    
    total = estabelecimentos.count
    Rails.logger.info "[GeocodeJob] #{total} estabelecimentos para processar"
    
    return if total.zero?
    
    processados = 0
    sucesso = 0
    
    estabelecimentos.find_each do |est|
      begin
        coords = geocode_address(est)
        
        if coords
          est.update_columns(
            latitude: coords[:lat],
            longitude: coords[:lng]
          )
          sucesso += 1
          Rails.logger.info "[GeocodeJob] ✓ #{est.cnpj_completo}: #{coords[:lat]}, #{coords[:lng]}"
        else
          Rails.logger.warn "[GeocodeJob] ✗ #{est.cnpj_completo}: não encontrado"
        end
        
        processados += 1
        
        # Aguarda 1.2 segundos para respeitar limite Nominatim (1 req/seg)
        sleep 1.2
        
      rescue => e
        Rails.logger.error "[GeocodeJob] Erro ao processar #{est.cnpj_completo}: #{e.message}"
      end
    end
    
    Rails.logger.info "[GeocodeJob] Concluído: #{sucesso}/#{processados} geocodificados com sucesso"
    
    # Se ainda há estabelecimentos para processar, agenda próximo lote
    if Estabelecimento.ativas.where(latitude: nil).exists?
      Rails.logger.info "[GeocodeJob] Agendando próximo lote em 5 minutos..."
      GeocodeEstabelecimentosJob.set(wait: 5.minutes).perform_later(batch_size: batch_size)
    else
      Rails.logger.info "[GeocodeJob] ✓ Todos estabelecimentos geocodificados!"
    end
  end
  
  private
  
  # Geocodifica um endereço usando Nominatim (OpenStreetMap)
  def geocode_address(estabelecimento)
    return nil unless estabelecimento.municipio.present?
    
    # Monta query de busca
    parts = []
    parts << [estabelecimento.tipo_logradouro, estabelecimento.logradouro].compact.join(' ') if estabelecimento.logradouro.present?
    parts << estabelecimento.numero if estabelecimento.numero.present?
    parts << estabelecimento.bairro if estabelecimento.bairro.present?
    parts << estabelecimento.municipio
    parts << estabelecimento.uf
    parts << 'Brasil'
    
    query = parts.join(', ')
    
    # Chamada à API Nominatim
    url = "https://nominatim.openstreetmap.org/search"
    response = HTTP
      .headers(
        'User-Agent' => 'MomentoFiscal/1.0 (contato@momentofiscal.df.gov.br)',
        'Accept-Language' => 'pt-BR,pt'
      )
      .get(url, params: {
        q: query,
        format: 'json',
        limit: 1,
        countrycodes: 'br'
      })
    
    return nil unless response.status.success?
    
    data = JSON.parse(response.body)
    return nil if data.empty?
    
    result = data.first
    {
      lat: result['lat'].to_f,
      lng: result['lon'].to_f
    }
    
  rescue => e
    Rails.logger.error "[GeocodeJob] Erro HTTP: #{e.message}"
    nil
  end
end
