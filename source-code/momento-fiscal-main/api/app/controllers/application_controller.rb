# frozen_string_literal: true

# ApplicationController
class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  respond_to :json

  before_action :authenticate_user!, unless: :skippable_controller

  def info_for_paper_trail
    {
      ip:                request.remote_ip,
      user_agent:        request.user_agent,
      controller_action: "#{controller_name}##{action_name}"
    }
  end

  def skippable_controller
    devise_controller?
  end
end
