# frozen_string_literal: true

class CepCoordinate < ApplicationRecord
  validates :cep, presence: true, uniqueness: true, length: { is: 8 }
  validates :latitude, :longitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true

  # Scopes
  scope :geocodificadas, -> { where.not(latitude: nil, longitude: nil) }
  scope :nao_encontradas, -> { where(latitude: nil).where.not(geocoded_at: nil) }
  scope :pendentes, -> { where(geocoded_at: nil) }
  scope :expiradas, ->(months = 6) { where('geocoded_at < ?', months.months.ago) }

  # Métodos de classe
  def self.find_or_create_by_cep(cep)
    find_or_create_by(cep: cep)
  end

  def self.bulk_update_from_geocoding_service(cep_coordinates_hash)
    """
    Atualiza múltiplas coordenadas em uma única operação
    
    Args:
      cep_coordinates_hash: Hash { 'cep_string' => [latitude, longitude], ... }
    """
    cep_coordinates_hash.each do |cep, (latitude, longitude)|
      if latitude && longitude
        find_or_create_by(cep: cep).update(
          latitude: latitude,
          longitude: longitude,
          geocoded_at: Time.current
        )
      else
        find_or_create_by(cep: cep).update(geocoded_at: Time.current)
      end
    end
  end

  # Métodos de instância
  def geocodificado?
    latitude.present? && longitude.present?
  end

  def nao_encontrado?
    geocoded_at.present? && !geocodificado?
  end

  def expirado?(months = 6)
    geocoded_at && geocoded_at < months.months.ago
  end

  # Retorna as coordenadas como array [lat, lng]
  def coordinates
    return nil unless geocodificado?
    [latitude, longitude]
  end

  # Retorna as coordenadas como hash (formato GeoJSON)
  def to_geojson
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [longitude, latitude] # GeoJSON usa [lng, lat]
      },
      properties: {
        cep: cep,
        geocoded_at: geocoded_at
      }
    }
  end
end
