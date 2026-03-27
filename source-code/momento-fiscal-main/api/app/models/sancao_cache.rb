# frozen_string_literal: true

# SancaoCache
# Armazena cache de consultas do Portal da Transparência (sanções)
class SancaoCache < ApplicationRecord
  self.table_name = "sancao_caches"

  TIPOS_CADASTRO = %w[CEIS CNEP CEPIM CEAF].freeze

  validates :cpf_cnpj, presence: true, length: { maximum: 14 }
  validates :tipo_cadastro, presence: true, inclusion: { in: TIPOS_CADASTRO }
  validates :cpf_cnpj, uniqueness: { scope: :tipo_cadastro }

  scope :por_documento, ->(doc) { where(cpf_cnpj: doc.to_s.gsub(/\D/, "")) }
  scope :validos, -> { where("checked_at > ?", 7.days.ago) }

  def cache_valid?
    checked_at.present? && checked_at > 7.days.ago
  end
end
