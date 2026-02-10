# frozen_string_literal: true

require "rails_helper"

RSpec.describe Institution do
  before do
    # Mocka o serviço de validação para sempre retornar true durante os testes
    allow(ValidateCnpjService).to receive(:call).and_return(true)
  end

  context "when validating attributes" do
    subject(:institution) { create(:institution) }

    it { is_expected.to validate_presence_of(:cnpj) }
    it { is_expected.to validate_uniqueness_of(:cnpj).case_insensitive }
    it { is_expected.to validate_length_of(:cnpj).is_equal_to(14) }
    it { is_expected.to allow_value("12345678901234").for(:cnpj) }

    it { is_expected.to validate_presence_of(:responsible_name) }
    it { is_expected.to validate_presence_of(:responsible_cpf) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:cell_phone) }
    it { is_expected.to validate_presence_of(:limit_debt) }

    it { is_expected.to allow_value("(12) 1234-5678").for(:phone) }
    it { is_expected.not_to allow_value("12345").for(:phone) }
    it { is_expected.to allow_value("(12) 98765-4321").for(:cell_phone) }
    it { is_expected.not_to allow_value("12345").for(:cell_phone) }
  end

  context "when managing associations" do
    it { is_expected.to have_many(:user_institutions).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_institutions) }
  end

  context "when validating custom CNPJ" do
    it "validates CNPJ using ValidateCnpjService" do
      institution = build(:institution, cnpj: "12345678901234")
      allow(ValidateCnpjService).to receive(:call).and_return(false)

      expect(institution).not_to be_valid
      expect(institution.errors[:cnpj]).to include("não é válido")
    end
  end

  context "when using pg_search_scope" do
    let!(:johns_institution) { create(:institution, cnpj: "76510583000162", responsible_name: "John Doe", email: "john@example.com") }
    let!(:janes_institution) { create(:institution, cnpj: "10017031000109", responsible_name: "Jane Doe", email: "jane@example.com") }

    it "searches by cnpj, responsible_name, or email" do
      results = described_class.text_search("John")

      expect(results).to include(johns_institution)
      expect(results).not_to include(janes_institution)
    end
  end

  context "when using model_query_filter" do
    let!(:institution_john) { create(:institution, cnpj: "76510583000162") }
    let!(:institution_jane) { create(:institution, cnpj: "10017031000109") }

    it "filters by text_search" do
      results = described_class.model_query_filter(described_class.all, :text_search, "76510583000162")

      expect(results).to include(institution_john)
      expect(results).not_to include(institution_jane)
    end

    it "filters by other keys" do
      results = described_class.model_query_filter(described_class.all, :cnpj, "10017031000109")

      expect(results).to include(institution_jane)
      expect(results).not_to include(institution_john)
    end
  end
end
