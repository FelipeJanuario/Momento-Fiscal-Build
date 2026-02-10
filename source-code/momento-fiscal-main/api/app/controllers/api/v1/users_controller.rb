# frozen_string_literal: true

module Api
  module V1
    # Controllers for users model
    class UsersController < ApplicationController
      before_action :set_user, only: %i[show update destroy]

      # GET /users
      # GET /users.json
      def index
        @users = User.query(params[:query]).paginate(page: params[:page], per_page: params[:per_page])
      end

      # GET /users/1
      # GET /users/1.json
      def show; end

      # POST /users
      # POST /users.json
      def create
        @user = User.new(user_params)

        if @user.save
          render :show, status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /users/1
      # PATCH/PUT /users/1.json
      def update
        if @user.update(user_params)

          @user.update(role: params[:user][:role]) if params[:user][:role].present?

          render :show, status: :ok
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # DELETE /users/1
      # DELETE /users/1.json
      def destroy
        @user.destroy
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_user
        @user = User.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def user_params
        params.require(:user).permit(:name, :email, :cpf, :phone, :birth_date, :sex, :ios_plan, :password,
                                     :password_confirmation)
      end
    end
  end
end
