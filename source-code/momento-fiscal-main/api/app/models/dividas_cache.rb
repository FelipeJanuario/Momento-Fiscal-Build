# frozen_string_literal: true

# DividasCache
# Armazena cache de consultas da API Serpro/PGFN para dívidas ativas
class DividasCache < ApplicationRecord
  self.table_name = "dividas_caches"

  validates :cnpj, presence: true, length: { is: 14 }
  validates :cnpj, uniqueness: { scope: :source }
  validates :debt_count, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :debt_value, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :source, inclusion: { in: %w[serpro pgfn] }

  scope :serpro, -> { where(source: "serpro") }
  scope :pgfn, -> { where(source: "pgfn") }

  # Define valores default antes da validação
  before_validation :set_defaults

  # Verifica se o cache ainda é válido (menos de 3 meses)
  def cache_valid?
    checked_at.present? && checked_at > 3.months.ago
  end

  private

  def set_defaults
    self.debt_count ||= 0
    self.debt_value ||= 0.0
    self.source ||= "serpro"
  end
end
