# frozen_string_literal: true

class Estabelecimento < ApplicationRecord
  belongs_to :empresa
  has_one :cep_coordinate, foreign_key: :cep, primary_key: :cep, dependent: nil

  validates :cnpj_completo, presence: true, uniqueness: true, length: { is: 14 }
  validates :cnpj_basico, presence: true
  validates :situacao_cadastral, presence: true

  # Situação Cadastral
  ATIVA = 2
  SUSPENSA = 3
  INAPTA = 4
  BAIXADA = 8

  # Scopes
  scope :ativas, -> { where(situacao_cadastral: ATIVA) }
  scope :matrizes, -> { where(identificador_matriz_filial: 1) }
  scope :filiais, -> { where(identificador_matriz_filial: 2) }
  scope :geocodificadas, -> { where.not(latitude: nil, longitude: nil) }
  scope :pendente_geocodificacao, -> { where(latitude: nil).where.not(cep: [nil, '']) }
  scope :com_divida_checada, -> { where.not(debt_checked_at: nil) }
  scope :divida_expirada, -> { where('debt_checked_at < ?', 3.months.ago) }

  # Busca por região (bounding box)
  scope :in_region, ->(lat, lng, radius_km) {
    # Cálculo aproximado: 1 grau de latitude ≈ 111km
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * Math.cos(lat * Math::PI / 180.0))

    where(
      latitude: (lat - lat_delta)..(lat + lat_delta),
      longitude: (lng - lng_delta)..(lng + lng_delta)
    ).geocodificadas
  }

  # Busca por prefixo de CEP (região geográfica)
  # CEPs brasileiros são geográficos: mesmos dígitos iniciais = mesma região
  # 3 dígitos = ~cidade/região, 5 dígitos = ~bairro
  scope :by_cep_prefix, ->(cep_prefix) {
    where('cep LIKE ?', "#{cep_prefix}%")
  }

  # Métodos
  def ativa?
    situacao_cadastral == ATIVA
  end

  def geocodificada?
    latitude.present? && longitude.present?
  end

  def debt_cache_valid?
    debt_checked_at.present? && debt_checked_at > 3.months.ago
  end

  def formatted_cnpj
    return cnpj_completo unless cnpj_completo.present?
    "#{cnpj_completo[0..1]}.#{cnpj_completo[2..4]}.#{cnpj_completo[5..7]}/#{cnpj_completo[8..11]}-#{cnpj_completo[12..13]}"
  end

  # Coordenadas: prioriza CEP coordinate se disponível, fallback para latitude/longitude locais
  def get_coordinates
    if cep_coordinate&.geocodificado?
      cep_coordinate.coordinates
    elsif latitude.present? && longitude.present?
      [latitude, longitude]
    else
      nil
    end
  end

  def get_coordinates_hash
    coords = get_coordinates
    return nil unless coords
    { latitude: coords[0], longitude: coords[1] }
  end
end
