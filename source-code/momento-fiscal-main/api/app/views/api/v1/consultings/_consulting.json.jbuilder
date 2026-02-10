# frozen_string_literal: true

json.extract! consulting, :id, :status, :value, :is_favorite, :client_id, :sent_at, :consultant_id, :created_at,
              :import_hash, :updated_at

if consulting.client.present?
  json.client do
    json.id consulting.client.id
    json.name consulting.client.name
  end
else
  json.client nil
end

if consulting.consultant.present?
  json.consultant do
    json.id consulting.consultant.id
    json.name consulting.consultant.name
  end
else
  json.consultant nil
end

json.url api_v1_consulting_url(consulting, format: :json)
