# frozen_string_literal: true

json.pagination_params do
  json.partial! "api/v1/pagination_params", paginated_collection: @institutions
end

json.data do
  json.array! @institutions, partial: "api/v1/institutions/institution", as: :institution
end
