# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserInstitution do
  # Nomeie o subject explicitamente
  let(:user_institution) { build(:user_institution) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:institution) }
  end

  describe "enums" do
    it "defines the role enum" do
      expect(user_institution).to define_enum_for(:role)
        .with_values(client: 0, consultant: 1, owner: 2)
        .backed_by_column_of_type(:integer)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(user_institution).to be_valid
    end
  end
end
