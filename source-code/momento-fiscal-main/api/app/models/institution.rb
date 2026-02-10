# frozen_string_literal: true

# Institution model
class Institution < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :text_search,
                  against: %i[cnpj responsible_name email],
                  using:   {
                    trigram: {
                      word_similarity: true
                    }
                  }

  validates :cnpj, presence: true, uniqueness: true, length: { is: 14 }, format: { with: /\A\d{14}\z/ }
  validates :responsible_name, presence: true
  validates :responsible_cpf, presence: true
  validates :email, presence: true
  validates :phone, presence: true, format: { with: /\A\(\d{2}\)\s\d{4,5}-\d{4}\z/ }
  validates :cell_phone, presence: true, format: { with: /\A\(\d{2}\)\s\d{4,5}-\d{4}\z/ }
  validates :limit_debt, presence: true

  validate :validate_cnpj

  has_many :user_institutions, dependent: :destroy
  has_many :users, through: :user_institutions

  def validate_cnpj
    return if ValidateCnpjService.call(cnpj:)

    errors.add(:cnpj, "não é válido")
  end

  def self.model_query_filter(query, key, value)
    return query.text_search(value) if key == :text_search

    query.where(key => value)
  end
end
