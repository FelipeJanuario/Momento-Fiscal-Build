class AddUniqueIndexToOabSubscriptionAndState < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :oab_subscription, unique: true

    add_index :users, [:oab_subscription, :oab_state]
  end
end
