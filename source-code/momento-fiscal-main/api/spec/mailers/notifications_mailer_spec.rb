# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsMailer do
  describe "email_notification" do
    let(:user) { create(:user, name: "Dr. Fulano de Tal") }
    let(:notification) { create(:notification, user:) }
    let(:mail) { described_class.email_notification(notification) }

    it "renders the headers" do
      expect(mail.subject).to eq(notification.title)
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["contato@spezi.com.br"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Ol=C3=A1 #{user.name},", notification.content,
                                           notification.title, notification.redirect_to)
    end
  end
end
