# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength
    # InvitationsController
    class InvitationsController < ApplicationController
      before_action :set_invitation, only: %i[show update destroy]
      skip_before_action :authenticate_user!, only: %i[create check update_status]
      before_action :authorize_admin!, only: [:create]

      # GET /invitations
      def index
        @invitations = Invitation.paginate(page: params[:page], per_page: params[:per_page])
        render json: @invitations
      end

      # GET /invitations/:id
      def show
        render json: @invitation
      end

      # POST /invitations
      def create
        existing_invitation = find_existing_invitation

        if existing_invitation
          handle_existing_invitation(existing_invitation)
        else
          create_new_invitation
        end
      end

      # PATCH/PUT /invitations/:id
      def update
        if @invitation.update(invitation_params)
          render json: @invitation, status: :ok
        else
          render json: @invitation.errors, status: :unprocessable_entity
        end
      end

      # DELETE /invitations/:id
      def destroy
        @invitation.destroy
        head :no_content
      end

      # GET /invitations/check?email=:email
      def check
        invitation = Invitation.find_by(email: params[:email])

        if invitation
          render json: {
            status:          invitation.status,
            send_invitation: invitation.user.name,
            created_at:      invitation.created_at
          }, status: :ok
        else
          render json: { error: "Convite não encontrado" }, status: :not_found
        end
      end

      # PUT /invitations/update_status?email=:email
      def update_status
        invitation = Invitation.find_by(email: params[:email])

        if invitation
          if invitation.update(status: params[:status])
            render json: { notice: "Status do convite atualizado com sucesso" }, status: :ok
          else
            render json: invitation.errors, status: :unprocessable_entity
          end
        else
          render json: { error: "Convite não encontrado" }, status: :not_found
        end
      end

      private

      # Encontra o convite existente
      def find_existing_invitation
        Invitation.find_by(email: invitation_params[:email])
      end

      # Lida com o convite existente, verificando se pode ser atualizado ou se há erro
      def handle_existing_invitation(invitation)
        if invitation_accepted?(invitation)
          render_invitation_accepted_error
        elsif invitation_expired?(invitation)
          update_existing_invitation(invitation)
        else
          render_invitation_error
        end
      end

      # Verifica se o convite já foi aceito (status == 1)
      def invitation_accepted?(invitation)
        invitation.status == 1
      end

      # Verifica se o convite já expirou (mais de 7 dias)
      def invitation_expired?(invitation)
        invitation.sent_at < 7.days.ago
      end

      # Renderiza erro se o convite foi aceito
      def render_invitation_accepted_error
        render json:   { error: "O convite não pode ser reenviado, pois já foi aceito." },
               status: :unprocessable_entity
      end

      # Renderiza erro se o convite foi enviado nos últimos 7 dias
      def render_invitation_error
        render json:   { error: "Já existe um convite enviado para este e-mail nos últimos 7 dias." },
               status: :unprocessable_entity
      end

      # Atualiza o convite existente e envia o e-mail novamente
      def update_existing_invitation(invitation)
        invitation.assign_attributes(status: 0, sent_at: Time.current)
        if invitation.save
          UserMailer.invitation_email(invitation).deliver_later
          render json: invitation, status: :ok
        else
          render json: invitation.errors, status: :unprocessable_entity
        end
      end

      # Cria uma nova instância de Invitation
      def build_new_invitation
        invitation = Invitation.new(invitation_params)
        invitation.sent_at = Time.current
        invitation.user_id = current_user.id
        invitation
      end

      # Cria novo convite e envia o e-mail
      def create_new_invitation
        @invitation = build_new_invitation
        save_and_send_invitation
      end

      # Salva a nova Invitation e envia o e-mail
      def save_and_send_invitation
        if @invitation.save
          UserMailer.invitation_email(@invitation).deliver_later
          render json: @invitation, status: :created
        else
          render json: @invitation.errors, status: :unprocessable_entity
        end
      end

      # Adiciona a verificação se o usuário é admin
      def authorize_admin!
        return if current_user.role == "admin"

        render json: { error: "Apenas administradores podem criar convites." }, status: :forbidden
      end

      # Use callbacks to share common setup or constraints between actions.
      def set_invitation
        @invitation = Invitation.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def invitation_params
        params.require(:invitation).permit(:email, :status)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
