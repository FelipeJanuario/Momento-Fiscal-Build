# frozen_string_literal: true

json.extract! consulting_proposal, :id, :consulting_id, :services,
              :description, :comment, :created_at, :updated_at
json.url api_v1_consulting_proposal_url(consulting_proposal, format: :json)
