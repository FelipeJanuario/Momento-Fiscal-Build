# frozen_string_literal: true

json.data do
  json.array! @user_institutions, partial: "api/v1/user_institutions/user_institution", as: :user_institution
end
