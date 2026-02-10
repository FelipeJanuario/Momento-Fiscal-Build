# frozen_string_literal: true

module Api
  module V1
    # ConsultingProposalsController
    class ConsultingProposalsController < ApplicationController
      before_action :validate_creation_authorization!, only: %i[create]
      before_action :set_consulting_proposal, only: %i[show update destroy]

      # GET /api/v1/consulting_proposals
      # GET /api/v1/consulting_proposals.json
      def index
        @consulting_proposals = ConsultingProposal.order(created_at: :desc).query(params[:query])
                                                  .paginate(
                                                    page:     params[:page],
                                                    per_page: params[:per_page]
                                                  )
      end

      # GET /api/v1/consulting_proposals/1
      # GET /api/v1/consulting_proposals/1.json
      def show
        respond_to do |format|
          format.json
          format.pdf do
            send_data @consulting_proposal.to_pdf, filename: "file.pdf"
          end
        end
      end

      # POST /api/v1/consulting_proposals
      # POST /api/v1/consulting_proposals.json
      # rubocop:disable Metrics/AbcSize
      def create
        @consulting_proposal = ConsultingProposal.new(consulting_proposal_params)
        @consulting_proposal.editor = current_user

        if @consulting_proposal.save
          Rails.cache.increment("#{current_user.cache_key}/consulting_proposal/create/counter", 1,
                                expires_in: Time.zone.now.end_of_day - Time.zone.now)
          render :show, status: :created, location: api_v1_consulting_proposal_url(@consulting_proposal)
        else
          render json: @consulting_proposal.errors, status: :unprocessable_entity
        end
      end
      # rubocop:enable Metrics/AbcSize

      # PATCH/PUT /api/v1/consulting_proposals/1
      # PATCH/PUT /api/v1/consulting_proposals/1.json
      def update
        @consulting_proposal.editor = current_user
        if @consulting_proposal.update(consulting_proposal_params)
          render :show, status: :ok, location: api_v1_consulting_proposal_url(@consulting_proposal)
        else
          render json: @consulting_proposal.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/consulting_proposals/1
      # DELETE /api/v1/consulting_proposals/1.json
      def destroy
        @consulting_proposal.destroy!
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_consulting_proposal
        @consulting_proposal = ConsultingProposal.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def consulting_proposal_params
        params.require(:consulting_proposal).permit(
          :consulting_id, :description, :comment, services: []
        )
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      def validate_creation_authorization!
        return true if current_user.role == "admin"
        return true if current_user.enabled_features.include?("limitless_proposals")

        count = Rails.cache.read("#{current_user.cache_key}/consulting_proposal/create/counter") || 0

        return true if current_user.enabled_features.include?("ten_proposals") && count < 10
        return true if current_user.enabled_features.include?("two_proposals") && count < 2

        render json: { error: "Unauthorized" }, status: :unauthorized
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
    end
  end
end
