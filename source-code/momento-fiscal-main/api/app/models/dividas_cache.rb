# frozen_string_literal: true

# DividasCache
# Armazena cache de consultas da API Serpro para dívidas ativas
class DividasCache < ApplicationRecord
  self.table_name = "dividas_caches"

  validates :cnpj, presence: true, uniqueness: true, length: { is: 14 }
  validates :debt_count, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :debt_value, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

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
  end
end
