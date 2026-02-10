class AddOabSubscriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :oab_subscription, :string, limit: 15
    add_column :users, :oab_state, :string, limit: 2

    add_index :users, :oab_subscription, unique: true
  end
end
