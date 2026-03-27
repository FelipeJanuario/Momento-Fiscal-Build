# frozen_string_literal: true

class CreateMunicipios < ActiveRecord::Migration[7.2]
  def change
    create_table :municipios do |t|
      t.string :codigo_ibge, null: false, limit: 7
      t.string :nome, null: false
      t.string :uf, null: false, limit: 2
      t.string :cnpj_prefeitura, limit: 14
      t.integer :populacao
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7

      t.timestamps
    end

    add_index :municipios, :codigo_ibge, unique: true
    add_index :municipios, :uf
    add_index :municipios, :nome
    add_index :municipios, :cnpj_prefeitura
  end
end
