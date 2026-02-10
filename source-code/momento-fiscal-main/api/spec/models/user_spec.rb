# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  # Test validations for presence
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:phone) }
  it { is_expected.to validate_presence_of(:birth_date) }
  it { is_expected.to validate_presence_of(:sex) }
  it { is_expected.to validate_presence_of(:cpf) }
  it { is_expected.to validate_presence_of(:oab_subscription).allow_blank }
  it { is_expected.to validate_presence_of(:oab_state).allow_blank }

  # Test format validations
  it { is_expected.to allow_value("user@example.com").for(:email) }
  it { is_expected.not_to allow_value("not-an-email").for(:email) }
  it { is_expected.to allow_value("(11) 99999-9999").for(:phone) }
  it { is_expected.not_to allow_value("123456789").for(:phone) }

  # Test enum
  it { is_expected.to define_enum_for(:sex).with_values(male: 0, female: 1, other: 2) }

  # Test custom validations
  describe "#validate_age" do
    it "adds an error if the birth_date is less than 18 years ago" do
      user = described_class.new(birth_date: 17.years.ago)
      user.validate_age
      expect(user.errors[:birth_date]).to include("não é válido")
    end

    it "does not add an error if the birth_date is more than 18 years ago" do
      user = described_class.new(birth_date: 19.years.ago)
      user.validate_age
      expect(user.errors[:birth_date]).to be_empty
    end
  end

  describe "#validate_cpf" do
    it "adds an error if the CPF is invalid" do
      allow(ValidateCpfService).to receive(:call).and_return(false)
      user = described_class.new(cpf: "invalid_cpf")
      user.validate_cpf
      expect(user.errors[:cpf]).to include("não é válido")
    end

    it "adds an error if the CPF has an invalid format" do
      user = described_class.new(cpf: "aaabbbcccdd")
      user.validate_cpf
      expect(user.errors[:cpf]).to include("não é válido")
    end
  end

  describe "validations" do
    it "is valid with a unique oab_subscription in a different state" do
      user1 = build_user("61995", "DF")
      user2 = build_user("61995", "MG")

      user1.save

      expect(user2).to be_valid
    end

    private

    def build_user(subscription, state)
      user = build(:user, oab_subscription: subscription, oab_state: state)
      allow(user).to receive(:validate_oab_subscription).and_return(true)
      user
    end

    it "is invalid with a unique oab_subscription in the same state" do
      user1 = build_user("61995", "DF")
      user2 = build_user("61995", "DF")

      user1.save

      expect(user2).not_to be_valid
    end

    private

    def build_user(subscription, state)
      user = build(:user, oab_subscription: subscription, oab_state: state)
      allow(user).to receive(:validate_oab_subscription).and_return(true)
      user
    end
  end

  # Test Devise modules
  describe "Devise modules" do
    it "includes database_authenticatable" do
      expect(described_class.devise_modules).to include(:database_authenticatable)
    end

    it "includes registerable" do
      expect(described_class.devise_modules).to include(:registerable)
    end

    it "includes trackable" do
      expect(described_class.devise_modules).to include(:trackable)
    end

    it "includes recoverable" do
      expect(described_class.devise_modules).to include(:recoverable)
    end

    it "includes rememberable" do
      expect(described_class.devise_modules).to include(:rememberable)
    end

    it "includes validatable" do
      expect(described_class.devise_modules).to include(:validatable)
    end
  end

  describe "#text_search" do
    it "searches for users by name and email" do
      user1 = create(:user, name: "Alice", phone: "(61) 99999-9999")
      user2 = create(:user, email: "alice.braga@teste.com", phone: "(61) 99999-9999")

      expect(described_class.text_search("alic")).to contain_exactly(user1, user2)
    end
  end
end
