# frozen_string_literal: true

# ConsultingProposal
class ConsultingProposal < ApplicationRecord
  belongs_to :consulting

  attr_accessor :editor

  after_save :notify_parties_about_update

  serialize :services, coder: JSON

  def notify_parties_about_update
    if client_editing?
      notify_consultant_about_comment
    elsif consultant_editing?
      notify_client_about_comment if consulting.client.present?
    end
  end

  def client_editing?
    consulting.client == editor
  end

  def consultant_editing?
    consulting.consultant == editor
  end

  def notify_consultant_about_comment
    return if consulting.consultant.blank?
    return if consulting.client.blank?

    consulting.consultant.notify(
      title:   "Novo comentário do cliente",
      content: "O cliente #{consulting.client.name} adicionou um comentário na
                proposta de número #{consulting_id}: #{comment}"
    )
  end

  def notify_client_about_comment
    return if consulting.client.blank?

    consulting.client.notify(
      title:   "Atualização na sua proposta de consultoria",
      content: "O consultor #{consulting.consultant.name} editou sua proposta de
                número #{consulting_id}: #{description_as_html}"
    )
  end

  def to_pdf
    RenderPdfService.new(
      template: "api/v1/consulting_proposals/show",
      layout:   "layouts/layout",
      assigns:  { consulting_proposal: self },
      formats:  [:pdf]
    ).call
  end

  def description_as_html
    delta = RichText::Delta.new(JSON.parse(description))
    delta.to_html
  end
end
