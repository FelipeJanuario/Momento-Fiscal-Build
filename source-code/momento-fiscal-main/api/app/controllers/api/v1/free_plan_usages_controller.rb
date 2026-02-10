# frozen_string_literal: true

module Api
  module V1
    # Controllers for Free Plans
    class FreePlanUsagesController < ApplicationController
      before_action :set_free_plan_usage, only: %i[show update]
      # GET /free_plan_usages
      def index
        @free_plan_usages = fetch_free_plan_usages
        expired_plans = update_expired_plans(@free_plan_usages)
        response_data = build_response_data(@free_plan_usages)

        render json: {
          message:          expired_message(expired_plans),
          expired_plan_ids: expired_plans.map(&:id),
          free_plan_usages: response_data
        }, status: :ok
      end

      def show; end

      # POST /free_plan_usages
      def create
        user_id = free_plan_usage_params[:user_id]
        if user_has_free_plan?(user_id)
          render json: { message: "Plano gratuito já utilizado" }, status: :ok
        else
          render_free_plan_creation
        end
      end

      # PUT /free_plan_usages/:id/update
      def update
        return if @free_plan_usage.user.role == "admin" && @free_plan_usage.status == "upgraded"

        if @free_plan_usage.update(free_plan_usage_params)
          render :show, status: :ok
        else
          render json: @free_plan_usage.errors, status: :unprocessable_entity
        end
      end

      private

      def user_has_free_plan?(user_id)
        User.find_by(id: user_id)&.free_plan_usage.present?
      end

      def render_free_plan_creation
        free_plan_usage = FreePlanUsage.new(free_plan_usage_params)

        if free_plan_usage.save
          render json:   { message: "Plano gratuito registrado com sucesso", free_plan_usage: free_plan_usage },
                 status: :created
        else
          render json: free_plan_usage.errors, status: :unprocessable_entity
        end
      end

      # Retorna o status do plano com base na data de criação
      def free_plan_status(free_plan)
        free_plan.status
      end

      def fetch_free_plan_usages
        FreePlanUsage.query(params[:query]).paginate(page: params[:page], per_page: params[:per_page])
      end

      def update_expired_plans(free_plan_usages)
        expired_plans = free_plan_usages
                        .where(created_at: ...7.days.ago)
                        .where.not(status: %w[expired upgraded])

        expired_plans.find_each do |plan|
          plan.update(status: "expired")
        end

        expired_plans
      end

      def build_response_data(free_plan_usages)
        free_plan_usages.map do |free_plan|
          {
            id:         free_plan.id,
            status:     free_plan_status(free_plan),
            created_at: free_plan.created_at
          }
        end
      end

      def expired_message(expired_plans)
        expired_plans.any? ? "Existem planos expirados, status atualizado" : "Nenhum plano expirado"
      end

      def set_free_plan_usage
        @free_plan_usage = FreePlanUsage.find(params[:id])
      end

      def free_plan_usage_params
        params.require(:free_plan_usage).permit(:user_id, :status)
      end
    end
  end
end
