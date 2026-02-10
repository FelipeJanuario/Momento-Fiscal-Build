# frozen_string_literal: true

class CreateEmpresasAndEstabelecimentos < ActiveRecord::Migration[7.0]
  def change
    # Tabela de Empresas (dados da matriz/base do CNPJ)
    create_table :empresas do |t|
      t.string :cnpj_basico, null: false, limit: 8, index: { unique: true }
      t.string :razao_social, null: false
      t.integer :natureza_juridica
      t.integer :qualificacao_responsavel
      t.decimal :capital_social, precision: 15, scale: 2
      t.integer :porte_empresa
      t.string :ente_federativo_responsavel

      t.timestamps
    end

    # Tabela de Estabelecimentos (cada CNPJ completo - matriz e filiais)
    create_table :estabelecimentos do |t|
      t.references :empresa, null: false, foreign_key: true
      t.string :cnpj_completo, null: false, limit: 14, index: { unique: true }
      t.string :cnpj_basico, null: false, limit: 8, index: true
      t.string :cnpj_ordem, null: false, limit: 4
      t.string :cnpj_dv, null: false, limit: 2
      t.integer :identificador_matriz_filial # 1=Matriz, 2=Filial
      t.string :nome_fantasia
      t.integer :situacao_cadastral, index: true # 2=ATIVA, 3=SUSPENSA, 4=INAPTA, 8=BAIXADA
      t.date :data_situacao_cadastral
      t.integer :motivo_situacao_cadastral
      t.date :data_inicio_atividade

      # Endereço
      t.string :tipo_logradouro
      t.string :logradouro
      t.string :numero
      t.string :complemento
      t.string :bairro
      t.string :cep, limit: 8, index: true
      t.string :uf, limit: 2
      t.integer :municipio
      t.string :ddd_1, limit: 4
      t.string :telefone_1, limit: 8
      t.string :ddd_2, limit: 4
      t.string :telefone_2, limit: 8
      t.string :ddd_fax, limit: 4
      t.string :fax, limit: 8
      t.string :email

      # CNAE
      t.integer :cnae_fiscal_principal
      t.string :cnae_fiscal_secundaria

      # Geolocalização (campos novos)
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.datetime :geocoded_at

      # Cache de dívidas SERPRO (campos novos)
      t.decimal :debt_value, precision: 15, scale: 2
      t.integer :debt_count
      t.datetime :debt_checked_at
      t.jsonb :debt_details

      t.timestamps
    end

    # Índice geográfico para busca por região
    add_index :estabelecimentos, [:latitude, :longitude], name: 'index_estabelecimentos_on_coordinates'
    
    # Índice composto para queries comuns
    add_index :estabelecimentos, [:situacao_cadastral, :cep], name: 'index_estabelecimentos_on_status_and_cep'
    add_index :estabelecimentos, [:debt_checked_at], where: 'debt_checked_at IS NOT NULL', name: 'index_estabelecimentos_on_debt_cache'
  end
end
