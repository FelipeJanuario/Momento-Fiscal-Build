# frozen_string_literal: true

# Divida
# Armazena dívidas ativas consultadas via SERPRO
class Divida < ApplicationRecord
  self.table_name = "dividas"

  validates :cnpj, presence: true, length: { is: 14 }
  validates :numero_inscricao, presence: true
  validates :cnpj, uniqueness: { scope: :numero_inscricao }

  scope :por_cnpj, ->(cnpj) { where(cnpj: cnpj.to_s.gsub(/\D/, '').rjust(14, '0')) }
  scope :valor_desc, -> { order(valor_consolidado: :desc) }

  # Formata valor para exibição
  def valor_formatado
    return 'R$ 0,00' if valor_consolidado.nil?

    'R$ ' + valor_consolidado.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end
end
