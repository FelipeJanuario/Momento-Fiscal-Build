# frozen_string_literal: true

class CreateDividas < ActiveRecord::Migration[7.2]
  def change
    create_table :dividas, id: :uuid do |t|
      t.string :cnpj, null: false, limit: 14
      t.string :numero_inscricao, null: false
      t.string :numero_processo
      t.string :situacao_inscricao
      t.string :situacao_descricao
      t.string :nome_devedor
      t.string :tipo_devedor
      t.decimal :valor_consolidado, precision: 15, scale: 2
      t.string :cpf_cnpj_formatado
      t.string :codigo_sida
      t.string :nome_unidade
      t.string :codigo_comprot
      t.string :codigo_uorg
      t.string :codigo_tipo_situacao
      t.string :descricao_tipo_situacao
      t.string :tipo_regularidade
      t.string :numero_juizo
      t.date :data_inscricao

      t.timestamps
    end

    add_index :dividas, :cnpj
    add_index :dividas, [:cnpj, :numero_inscricao], unique: true
  end
end
