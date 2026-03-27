# frozen_string_literal: true

class CreateSancaoCaches < ActiveRecord::Migration[7.2]
  def change
    create_table :sancao_caches do |t|
      t.string :cpf_cnpj, null: false, limit: 14
      t.string :tipo_cadastro, null: false # CEIS, CNEP, CEPIM, CEAF
      t.jsonb :dados, default: []
      t.datetime :checked_at

      t.timestamps
    end

    add_index :sancao_caches, %i[cpf_cnpj tipo_cadastro], unique: true
    add_index :sancao_caches, :checked_at
  end
end
