class AddUniqueIndexToFreePlanUsagesUserId < ActiveRecord::Migration[7.2]
  def change
    remove_index :free_plan_usages, :user_id
    add_index :free_plan_usages, :user_id, unique: true
  end
end
