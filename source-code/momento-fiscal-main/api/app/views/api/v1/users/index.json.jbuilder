# frozen_string_literal: true

json.pagination_params do
  json.partial! "api/v1/pagination_params", paginated_collection: @users
end

json.data do
  json.array! @users, partial: "api/v1/users/user", as: :user
end
