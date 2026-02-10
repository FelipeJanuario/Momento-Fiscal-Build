# frozen_string_literal: true

module Api
  module V1
    # Controllers for user institution model
    class UserInstitutionsController < ApplicationController
      before_action :set_user_institution, only: %i[show]

      # GET /user_institutions
      # GET /user_institutions.json
      def index
        @user_institutions = UserInstitution.query(params[:query]).paginate(page:     params[:page],
                                                                            per_page: params[:per_page])
      end

      # GET /user_institutions/1
      # GET /user_institutions/1.json
      def show; end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_user_institution
        @user_institutions = UserInstitution.find(params[:id])
      end
    end
  end
end
