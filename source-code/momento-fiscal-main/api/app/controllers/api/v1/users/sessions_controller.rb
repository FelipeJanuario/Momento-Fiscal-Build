# frozen_string_literal: true

module Api
  module V1
    module Users
      # Sessions for users that will use the system
      class SessionsController < Devise::SessionsController
        respond_to :json

        # rubocop:disable Metrics/AbcSize
        def create
          self.resource = warden.authenticate(auth_options)

          render json: { error: "Usuário não encontrado." }, status: :not_found and return if resource.blank?

          sign_in(resource_name, resource)

          render json: resource.errors.messages, status: :unauthorized and return if resource.errors.any?

          render partial: "api/v1/users/authentication", locals: { user: resource }
        end
        # before_action :configure_sign_in_params, only: [:create]

        # GET /resource/sign_in
        # def new
        #   super
        # end

        # POST /resource/sign_in
        # def create
        #   super
        # end

        # DELETE /resource/sign_out
        def destroy
          super do |_resource|
            render json: { message: "Signed out successfully" }, status: :ok and return
          end
        end

        # rubocop:enable Metrics/AbcSize

        protected

        # If you have extra params to permit, append them to the sanitizer.
        def configure_sign_in_params
          devise_parameter_sanitizer.permit(:sign_in, keys: [:identity])
        end

        private

        def respond_to_on_destroy
          head :no_content
        end
      end
    end
  end
end
