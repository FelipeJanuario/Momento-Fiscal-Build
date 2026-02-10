# frozen_string_literal: true

module Api
  module V1
    # InstitutionsController
    class InstitutionsController < ApplicationController
      before_action :authenticate_user!, except: [:create]
      before_action :set_institution, only: %i[show update destroy]

      # GET /institutions
      # GET /institutions.json
      def index
        @institutions = Institution.query(params[:query]).paginate(page: params[:page], per_page: params[:per_page])
      end

      # GET /institutions/1
      # GET /institutions/1.json
      def show; end

      # POST /institutions
      # POST /institutions.json
      def create
        ActiveRecord::Base.transaction do
          create_user_and_institution
        rescue ActiveRecord::RecordInvalid => e
          handle_create_error(e)
          raise ActiveRecord::Rollback
        end
      end

      # PATCH/PUT /institutions/1
      # PATCH/PUT /institutions/1.json
      def update
        if @institution.update(institution_params)
          render :show, status: :ok
        else
          render json: @institution.errors, status: :unprocessable_entity
        end
      end

      # DELETE /institutions/1
      # DELETE /institutions/1.json
      def destroy
        @institution.destroy!
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_institution
        @institution = Institution.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def institution_params
        params.require(:institution).permit(:cnpj, :responsible_name, :responsible_cpf, :email, :phone, :cell_phone,
                                            :limit_debt)
      end

      def create_user_and_institution
        @user = User.create!(user_params)
        @institution = Institution.create!(institution_params)
        UserInstitution.create!(user: @user, institution: @institution, role: :owner)
        render :show, status: :created
      end

      def user_params
        params.require(:user).permit(:name, :cpf, :phone, :email, :birth_date, :sex, :password, :password_confirmation)
      end

      def handle_create_error(error)
        if @user&.errors.present?
          render json: { **@user.errors, model: :user }, status: :unprocessable_entity
        elsif @institution&.errors.present?
          render json: { **@institution.errors, model: :institution }, status: :unprocessable_entity
        else
          render json: { error: [error.message] }, status: :unprocessable_entity
        end
      end
    end
  end
end
