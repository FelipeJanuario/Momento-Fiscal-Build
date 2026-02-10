# frozen_string_literal: true

require "active_support/concern"

# Queryable concern
# This concern is used to filter and order the collection with sql querys
module Queryable
  extend ActiveSupport::Concern

  FILTERED_PARAMS = %w[page per_page order].freeze

  # rubocop:disable Metrics/BlockLength
  class_methods do
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    # This method is the main entry point for querying the model.
    # It applies filters and ordering to the query based on the provided parameters.
    # @param params [String, Hash] The query parameters
    # @return [ActiveRecord::Relation] The query result
    def query(params = nil)
      query_params = query_params(params)
      query        = query_collection

      query = query.reorder(query_params[:order]) if query_params[:order].present?

      return query if query_params.blank?

      query_params.each do |key, value|
        next if FILTERED_PARAMS.include?(key)
        next if value.blank?

        next query = yield(query, key.to_sym, value) if block_given?

        query = query_filter(query, key.to_sym, value)
      end

      query
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    # rubocop:disable Metrics/AbcSize
    # This method applies a filter to the query based on the key and value provided.
    # It supports greater than, greater than or equal to, less than, less than or equal to, and string matching.
    # If none of these conditions match, it delegates to the `model_query_filter` method.
    # @param query [ActiveRecord::Relation] The current query
    # @param key [String] The attribute to filter on
    # @param value [String, Integer, Date, etc.] The value to filter with
    # @return [ActiveRecord::Relation] The filtered query
    def query_filter(query, key, value)
      return query.where(arel_table[key.remove(/^gt_/)].gt(value))  if /^gt_/.match?(key)
      return query.where(key.remove(/^gte_/) => value..)            if /^gte_/.match?(key)
      return query.where(arel_table[key.remove(/^lt_/)].lt(value))  if /^lt_/.match?(key)
      return query.where(key.remove(/^lte_/) => ..value)            if /^lte_/.match?(key)

      return query.where(arel_table[key].matches("%#{value}%")) if columns_hash[key.to_s]&.type == :string

      model_query_filter(query, key, value)
    end
    # rubocop:enable Metrics/AbcSize

    # This method applies a simple equality filter to the query based on the key and value provided.
    # Its purpose is to be overridden by the model to provide custom filtering.
    # @param query [ActiveRecord::Relation] The current query
    # @param key [String] The attribute to filter on
    # @param value [String, Integer, Date, etc.] The value to filter with
    # @return [ActiveRecord::Relation] The filtered query
    def model_query_filter(query, key, value)
      query.where(key => value)
    end

    # This method provides the default model collection to be queried.
    # Its purpose is to be overridden by the model to provide customization.
    # @return [ActiveRecord::Relation] The ordered query
    def query_collection
      order(query_default_order)
    end

    # This method defines the default order for the query.
    # Its purpose is to be overridden by the model to provide customization.
    # @return [Hash] The default order
    def query_default_order
      { id: :asc }
    end

    # This method processes the query parameters.
    # It first checks if the params are a string and if so, parses them into JSON.
    # It then ensures that the params are not nil by setting them to an empty hash if they are.
    # Finally, it transforms the keys of the params to strings, underscores them, and allows them to be accessed
    # indifferently.
    # @param params [String, Hash] The query parameters
    # @return [Hash] The processed query parameters
    def query_params(params)
      query_params = JSON.parse(params) if params.is_a?(String)
      query_params ||= params
      query_params ||= {}

      query_params.as_json.transform_keys(&:to_s).transform_keys(&:underscore).with_indifferent_access
    end
  end
  # rubocop:enable Metrics/BlockLength
end
