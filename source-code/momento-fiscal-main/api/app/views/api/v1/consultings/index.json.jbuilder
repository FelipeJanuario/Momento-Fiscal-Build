# frozen_string_literal: true

json.pagination_params do
  json.partial! "api/v1/pagination_params", paginated_collection: @consultings
end

json.data do
  json.array! @consultings, partial: "api/v1/consultings/consulting", as: :consulting
end
