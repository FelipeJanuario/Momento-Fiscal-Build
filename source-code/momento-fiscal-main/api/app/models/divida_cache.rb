# frozen_string_literal: true

# Model para cache de consultas de dívidas do Serpro
class DividaCache < ApplicationRecord
  self.primary_key = 'cnpj'
  
  # Validações
  validates :cnpj, presence: true, uniqueness: true, length: { is: 14 }
  
  # Verifica se o cache é válido (menos de 3 meses)
  def cache_valid?
    debt_checked_at.present? && debt_checked_at > 3.months.ago
  end
  
  # Atualiza os dados de dívida
  def update_debt_data(debt_count:, debt_value:, razao_social: nil, nome_fantasia: nil, situacao_cadastral: nil)
    update(
      debt_count: debt_count,
      debt_value: debt_value,
      debt_checked_at: Time.current,
      razao_social: razao_social || self.razao_social,
      nome_fantasia: nome_fantasia || self.nome_fantasia,
      situacao_cadastral: situacao_cadastral || self.situacao_cadastral
    )
  end
end
