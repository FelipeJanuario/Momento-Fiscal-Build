# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/api/v1/free_plan_usages" do
  let(:current_user) { create(:user) }
  let(:valid_headers) { { Authorization: "Bearer #{current_user.token}" } }

  describe "GET /index" do
    context "when there are active and expired plans" do
      let!(:user_old_active) { create(:user) }
      let!(:user_new_active) { create(:user) }
      let!(:user_expired)    { create(:user) }

      before do
        FreePlanUsage.create!(user: user_old_active, status: "active", created_at: 10.days.ago)
        FreePlanUsage.create!(user: user_new_active, status: "active", created_at: 2.days.ago)
        FreePlanUsage.create!(user: user_expired, status: "expired", created_at: 15.days.ago)
      end

      it "returns all plans" do
        get "/api/v1/free_plan_usages", headers: valid_headers, as: :json
        expect(response).to be_successful

        json = response.parsed_body
        expect(json["free_plan_usages"].map { |p| p["status"] }).to include("expired", "active")
      end

      it "expires only old active plans" do
        controller = Api::V1::FreePlanUsagesController.new
        controller.send(:update_expired_plans, FreePlanUsage.all)
        old_active_plan = FreePlanUsage.find_by(user: user_old_active)

        expect(old_active_plan.reload.status).to eq("expired")
        expect(FreePlanUsage.find_by(user: user_new_active).status).to eq("active")
      end
    end

    context "when there are no expired plans" do
      let!(:user_active) { create(:user) }

      before do
        FreePlanUsage.create!(user: user_active, status: "active", created_at: 2.days.ago)
      end

      it "returns message indicating no expired plans" do
        get "/api/v1/free_plan_usages", headers: valid_headers, as: :json
        expect(response).to be_successful

        json = response.parsed_body
        expect(json["message"]).to eq("Nenhum plano expirado")
      end
    end
  end

  describe "#update_expired_plans (private method)" do
    let!(:user_old_active) { create(:user) }
    let!(:user_new_active) { create(:user) }
    let!(:user_expired)    { create(:user) }
    let!(:user_upgraded)   { create(:user) }

    let!(:old_active_plan) { FreePlanUsage.create!(user: user_old_active, status: "active", created_at: 10.days.ago) }
    let!(:new_active_plan) { FreePlanUsage.create!(user: user_new_active, status: "active", created_at: 2.days.ago) }
    let!(:expired_plan)    { FreePlanUsage.create!(user: user_expired, status: "expired", created_at: 20.days.ago) }
    let!(:upgraded_plan)   { FreePlanUsage.create!(user: user_upgraded, status: "upgraded", created_at: 15.days.ago) }

    it "expires only old active plans" do
      controller = Api::V1::FreePlanUsagesController.new
      controller.send(:update_expired_plans, FreePlanUsage.all)

      expect(old_active_plan.reload.status).to eq("expired")
      expect(new_active_plan.reload.status).to eq("active")
    end

    it "does not change expired or upgraded plans" do
      controller = Api::V1::FreePlanUsagesController.new
      controller.send(:update_expired_plans, FreePlanUsage.all)

      expect(expired_plan.reload.status).to eq("expired")
      expect(upgraded_plan.reload.status).to eq("upgraded")
    end
  end
end
