# frozen_string_literal: true

class CreateCepCoordinates < ActiveRecord::Migration[7.0]
  def change
    # Usa IF NOT EXISTS para não falhar se a tabela já existir
    return if table_exists?(:cep_coordinates)
    
    create_table :cep_coordinates do |t|
      t.string :cep, null: false, limit: 8, index: { unique: true }
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.datetime :geocoded_at
      t.timestamps
    end

    # Índice para buscas por geocodificação válida
    add_index :cep_coordinates, [:latitude, :longitude], where: 'latitude IS NOT NULL AND longitude IS NOT NULL', name: 'index_cep_coordinates_on_valid_coordinates'
    
    # Índice para CEPs que não foram encontrados (otimiza busca de pendentes)
    add_index :cep_coordinates, [:geocoded_at], where: 'latitude IS NULL', name: 'index_cep_coordinates_on_not_found'
  end
end
