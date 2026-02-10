# frozen_string_literal: true

# ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include Queryable

  scope :paginate, lambda { |page: 1, per_page: 10|
    limit(per_page&.to_i || 10).offset((per_page&.to_i || 1) * ((page&.to_i || 1) - 1))
  }
end
