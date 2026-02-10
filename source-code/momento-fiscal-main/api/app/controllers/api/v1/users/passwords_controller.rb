# frozen_string_literal: true

module Api
  module V1
    module Users
      # Controller para gerenciar a redefinição de senha dos usuários.
      # Extende o Devise::PasswordsController.
      class PasswordsController < Devise::PasswordsController
        # POST /resource/password
        def create
          user = User.find_for_authentication(identity: params[:user][:identity])

          if user.present?
            send_reset_password_instructions(user)
            render_success_response(user)
          else
            render json: { error: "Usuário não encontrado." }, status: :not_found
          end
        end

        # rubocop:disable Metrics/AbcSize
        # PUT /resource/password
        def update
          user = find_user_by_token(params[:user][:reset_password_token])

          return render_invalid_token_error unless user.present? && reset_token_valid?(user)

          if Devise::Encryptor.compare(User, user.encrypted_password, params[:user][:password])
            render json:   { error: "A nova senha não pode ser igual a atual." },
                   status: :unprocessable_entity
          elsif update_password(user, params[:user][:password], params[:user][:password_confirmation])
            render json: { message: "Senha atualizada com sucesso." }, status: :ok
          else
            render json: { error: "Não foi possível atualizar a senha." }, status: :unprocessable_entity
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def send_reset_password_instructions(user)
          user.generate_reset_password_token!
          UserMailer.with(user:).send_reset_password_code.deliver_later
        end

        def render_success_response(user)
          render json: {
            email:   user.email,
            code:    user.reset_password_token,
            message: "Código de redefinição de senha enviado para o seu e-mail."
          }, status: :ok
        end

        def find_user_by_token(token)
          User.find_by(reset_password_token: token)
        end

        def update_password(user, password, password_confirmation)
          user.reset_password(password, password_confirmation)
        end

        def render_invalid_token_error
          render json: { error: "Código de redefinição de senha inválido ou expirado." }, status: :unprocessable_entity
        end

        def reset_token_valid?(user)
          user.reset_password_token_valid?
        end
      end
    end
  end
end
