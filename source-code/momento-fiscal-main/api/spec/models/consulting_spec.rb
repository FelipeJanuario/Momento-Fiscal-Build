# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consulting do
  describe "associations" do
    it { is_expected.to have_many(:consulting_proposals).dependent(:destroy) }
  end

  describe "validations" do
    let(:client) { create(:user, phone: "(61) 99999-9999") }
    let(:consultant) { create(:user, phone: "(61) 99999-9999") }
    let(:valid_attributes) do
      {
        client:,
        consultant:,
        status:      :not_started,
        debts_count: 15,
        value:       1000.0
      }
    end

    let(:invalid_attributes) do
      {
        client:      nil,
        consultant:  nil,
        status:      nil,
        debts_count: 5,
        value:       -1.0
      }
    end

    it "is valid with valid attributes" do
      consulting = described_class.new(valid_attributes)
      expect(consulting).to be_valid
    end

    it "is invalid without a status" do
      consulting = described_class.new(valid_attributes.merge(status: nil))
      expect(consulting).not_to be_valid
      expect(consulting.errors[:status]).to include("não pode ficar em branco")
    end

    it "is invalid with a negative value" do
      consulting = described_class.new(valid_attributes.merge(value: -100))
      expect(consulting).not_to be_valid
      expect(consulting.errors[:value]).to include("deve ser maior ou igual a 0")
    end
  end

  describe "enums" do
    it "has the correct statuses" do
      expect(described_class.statuses).to include("not_started" => 0, "waiting" => 1, "approved" => 2, "in_progress" => 3, "finished" => 4, "failed" => 5)
    end
  end

  describe ".model_query_filter" do
    let(:low_value_consulting) { create(:consulting, value: 500, status: :not_started) }
    let(:high_value_consulting) { create(:consulting, value: 1500, status: :approved) }

    it "filters by value when key is 'value'" do
      query = described_class.all
      result = described_class.model_query_filter(query, "value", 1000)
      expect(result).to include(low_value_consulting)
      expect(result).not_to include(high_value_consulting)
    end
  end
end
