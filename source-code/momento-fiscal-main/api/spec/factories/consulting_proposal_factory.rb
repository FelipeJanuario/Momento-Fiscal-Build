# frozen_string_literal: true

FactoryBot.define do
  factory :consulting_proposal, class: "ConsultingProposal" do
    description { "MyText" }

    consulting
  end
end
