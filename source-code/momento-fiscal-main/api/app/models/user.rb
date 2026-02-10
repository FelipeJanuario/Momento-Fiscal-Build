# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

# User
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist
  include PgSearch::Model

  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :trackable,
         :recoverable, :rememberable, :validatable, :lockable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  pg_search_scope :text_search,
                  against: %i[name email],
                  using:   {
                    trigram: {
                      word_similarity: true
                    }
                  }

  encrypts :cpf, deterministic: true, downcase: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :phone, presence: true, format: { with: /\A\(\d{2}\)\s\d{4,5}-\d{4}\z/ }
  validates :birth_date, presence: true
  validates :sex, presence: true
  validates :cpf, presence: true, uniqueness: true
  validates :oab_subscription,
            uniqueness:  { scope: :oab_state, message: :taken_in_state },
            allow_blank: true,
            if:          -> { oab_subscription.present? }
  validate :validate_age
  validate :validate_cpf
  validate :validate_oab_subscription, if: -> { oab_subscription.present? }

  has_many :notifications, dependent: :destroy
  has_many :user_institutions, dependent: :destroy
  has_many :institutions, through: :user_institutions
  has_many :clients_consultings, class_name: "Consulting", foreign_key: :client_id,
                                                        dependent: :restrict_with_exception,
                                                        inverse_of: :client

  has_many :consultants_constutings, class_name: "Consulting", foreign_key: :consultant_id,
                                                        dependent: :nullify,
                                                        inverse_of: :consultant

  has_many :invitations, dependent: :nullify
  has_one :free_plan_usage, dependent: :destroy
  has_one :google_subscription, class_name: "Google::Subscription", inverse_of: :user, dependent: :destroy

  after_create :create_stripe_customer, unless: :stripe_customer_id?

  enum :sex, {
    male:   0,
    female: 1,
    other:  2
  }

  enum :role, {
    client:     0,
    consultant: 1,
    admin:      2
  }

  def token
    @token ||= begin
      token, payload = Warden::JWTAuth::UserEncoder.new.call(self, :user, nil)
      on_jwt_dispatch(token, payload)
      token
    end
  end

  def validate_age
    return if birth_date.blank?

    errors.add(:birth_date, "não é válido") if birth_date > 18.years.ago
  end

  def validate_cpf
    return errors.add(:cpf, "não é válido") unless /\A\d{11}\z/.match?(cpf)

    return if ValidateCpfService.call(cpf:)

    errors.add(:cpf, "não é válido")
  end

  def validate_oab_subscription
    return if ValidateOabSubscriptionService.call(oab: oab_subscription, state: oab_state)

    errors.add(:oab_subscription, "não encontrada na base da OAB ou estado")
  end

  def create_stripe_customer
    return if Rails.env.test? || stripe_customer_id.present? || ENV['DEV_MODE'] == 'true'

    stripe_customer = Stripe::Customer.create(email:, name:, phone:, preferred_locales: %w[pt-BR pt en],
                                              metadata: { user_id: id })

    return if stripe_customer.id.nil?
    return @stripe_customer = stripe_customer if update(stripe_customer_id: stripe_customer.id)

    Stripe::Customer.delete(stripe_customer.id)
  end

  def stripe_customer
    return create_stripe_customer if stripe_customer_id.blank?

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def stripe_subscriptions
    return [] if stripe_customer_id.blank?

    @stripe_subscriptions ||= Stripe::Subscription.list(customer: stripe_customer_id).data
  end

  def active_stripe_subscription
    @active_stripe_subscription ||= Stripe::Subscription.list(customer: stripe_customer_id,
                                                              status:   "active").data&.first
  end

  def stripe_active_entitlements
    return [] if stripe_customer_id.blank?

    @stripe_active_entitlements ||= Stripe::Entitlements::ActiveEntitlement.list(customer: stripe_customer_id,
                                                                                 limit:    100).data
  end

  def enabled_features
    Rails.cache.fetch("user/#{id}/enabled_features", expires_in: 1.minute) do
      stripe_active_entitlements.map(&:lookup_key)
    end
  end

  def self.model_query_filter(query, key, value)
    return query.distinct.joins(:institutions).where(institutions: { id: value }) if key == :institution_id
    return query.text_search(value)                                               if key == :text_search

    query.where(key => value)
  end

  def self.find_for_authentication(params)
    identity = params[:identity].strip.gsub(/[^0-9]/, "")

    return where(cpf: identity).first if identity.length == 11
    return joins(:institutions).where(institutions: { cnpj: identity }).first if identity.length == 14

    raise ArgumentError, "Invalid credentials"
  end

  def generate_reset_password_token!
    token = (SecureRandom.random_number(9e5) + 1e5).to_i
    self.reset_password_token = token
    self.reset_password_sent_at = Time.now.utc
    save(validate: false)
  end

  def reset_password_token_valid?
    (reset_password_sent_at + 2.hours) > Time.now.utc
  end

  def notify(title:, content:, redirect_to: nil)
    notifications.create!(title:, content:, redirect_to:)
  end

  def check_free_plan_status
    if free_plan_usage
      return "Plano free já está em uso." if free_plan_usage.created_at > 7.days.ago

      "Plano grátis já foi utilizado."

    else
      # Criação do registro de uso do plano gratuito
      create_free_plan_usage!
      "Plano free ativado com sucesso!"
    end
  end
end

# rubocop:enable Metrics/ClassLength
