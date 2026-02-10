# frozen_string_literal: true

module Api
  module V1
    # ConsultingsController
    class ConsultingsController < ApplicationController
      before_action :set_consulting, only: %i[show update destroy]

      # GET /consultings
      # GET /consultings.json
      def index
        @consultings = Consulting.includes(:client, :consultant)
                                 .query(params[:query])
                                 .reorder(
                                   is_favorite: :desc,
                                   id:          :asc
                                 )
                                 .paginate(
                                   page:     params[:page],
                                   per_page: params[:per_page]
                                 )
      end

      # GET /consultings/1
      # GET /consultings/1.json
      def show; end

      # POST /consultings
      # POST /consultings.json
      def create
        @consulting = Consulting.new(consulting_params)

        @consulting.generate_unique_import_hash if @consulting.client_id.nil?

        if @consulting.save
          render :show, status: :created
        else
          render json: @consulting.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /consultings/1
      # PATCH/PUT /consultings/1.json
      def update
        if @consulting.update(consulting_params)
          render :show, status: :ok
        else
          render json: @consulting.errors, status: :unprocessable_entity
        end
      end

      def import
        @consulting = Consulting.where(client_id: nil).find_by(import_hash: params[:import_hash]&.upcase)

        raise ActiveRecord::RecordNotFound if @consulting.nil?

        @consulting.update!(client_id: current_user.id)
        render :show, status: :ok
      end

      # DELETE /consultings/1
      # DELETE /consultings/1.json
      def destroy
        @consulting.destroy!
        head :no_content
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_consulting
        @consulting = Consulting.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def consulting_params
        params.require(:consulting).permit(:status, :value, :debts_count, :sent_at, :is_favorite, :client_id,
                                           :consultant_id)
      end
    end
  end
end
