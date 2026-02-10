# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitation do
  context "when validating attributes" do
    subject(:invitation) { build(:invitation) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to allow_value("test@example.com").for(:email) }
    it { is_expected.not_to allow_value("Email não é válido").for(:email) }
  end

  context "when managing status enum" do
    it "has the correct enum values" do
      expect(described_class.statuses).to eq("pending" => 0, "accepted" => 1, "declined" => 2)
    end

    it "allows pending status" do
      invitation = build(:invitation, status: :pending)
      expect(invitation).to be_valid
    end

    it "allows accepted status" do
      invitation = build(:invitation, status: :accepted)
      expect(invitation).to be_valid
    end

    it "allows declined status" do
      invitation = build(:invitation, status: :declined)
      expect(invitation).to be_valid
    end
  end

  context "when setting sent_at before creation" do
    it "sets sent_at automatically" do
      invitation = build(:invitation, sent_at: nil)
      expect(invitation.sent_at).to be_nil

      invitation.save!
      expect(invitation.sent_at).not_to be_nil
    end

    it "does not overwrite sent_at if already set" do
      fixed_time = 1.day.ago
      invitation = build(:invitation, sent_at: fixed_time)

      invitation.save!

      expect(invitation.sent_at.change(usec: 0)).to eq(fixed_time.change(usec: 0))
    end
  end
end
