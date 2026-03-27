# frozen_string_literal: true

# Municipio
# Dados de municípios brasileiros (importação IBGE)
class Municipio < ApplicationRecord
  self.table_name = "municipios"

  validates :codigo_ibge, presence: true, uniqueness: true, length: { is: 7 }
  validates :nome, presence: true
  validates :uf, presence: true, length: { is: 2 }

  scope :por_uf, ->(uf) { where(uf: uf.upcase) }
  scope :buscar_nome, ->(termo) { where("nome ILIKE ?", "%#{sanitize_sql_like(termo)}%") }
end
