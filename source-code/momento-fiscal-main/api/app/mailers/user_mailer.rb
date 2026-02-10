# frozen_string_literal: true

# Mailer para enviar o código de redefinição de senha aos usuários.
class UserMailer < ApplicationMailer
  def send_reset_password_code
    @user = params[:user]
    mail(to: @user.email, subject: I18n.t("devise.mailer.reset_password.subject"))
  end

  def invitation_email(user)
    @user = user
    mail(to: @user.email, subject: I18n.t("devise.mailer.invitation.send_invitation"))
  end
end
