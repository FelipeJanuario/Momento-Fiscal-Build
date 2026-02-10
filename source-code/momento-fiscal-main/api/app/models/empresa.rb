# frozen_string_literal: true

class Empresa < ApplicationRecord
  has_many :estabelecimentos, dependent: :destroy

  validates :cnpj_basico, presence: true, uniqueness: true, length: { is: 8 }
  validates :razao_social, presence: true

  # Scopes
  scope :ativas, -> { joins(:estabelecimentos).where(estabelecimentos: { situacao_cadastral: 2 }).distinct }
end
