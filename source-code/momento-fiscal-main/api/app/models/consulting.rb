# frozen_string_literal: true

# Consulting model
class Consulting < ApplicationRecord
  belongs_to :client, class_name: "User", optional: true
  belongs_to :consultant, class_name: "User", optional: true

  before_create :generate_unique_import_hash

  has_many :consulting_proposals, dependent: :destroy

  validates :status, presence: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :status,
       { not_started: 0, waiting: 1, approved: 2, in_progress: 3, finished: 4, failed: 5, waiting_for_user_creation: 6 }

  def self.model_query_filter(query, key, value)
    return query.where(value: ..value).order(value: :desc) if key == "value"

    super
  end

  def generate_unique_import_hash
    return unless client_id.nil?

    loop do
      self.import_hash = SecureRandom.base36(6).upcase
      break unless Consulting.exists?(import_hash:)
    end
  end
end
