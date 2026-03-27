# frozen_string_literal: true

class AddSubscriptionStatusToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :subscription_status, :string, default: "inactive", null: false
    add_index :users, :subscription_status
  end
end
