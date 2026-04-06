# frozen_string_literal: true

class AddTestFeaturesOverrideToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :test_features_override, :text, array: true, default: [], null: false
  end
end
