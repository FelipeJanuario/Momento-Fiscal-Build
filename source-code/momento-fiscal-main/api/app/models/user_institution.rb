# frozen_string_literal: true

# UserInstitution
class UserInstitution < ApplicationRecord
  belongs_to :user
  belongs_to :institution

  enum :role, { client: 0, consultant: 1, owner: 2 }
end
