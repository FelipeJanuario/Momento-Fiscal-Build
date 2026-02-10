class CreateFreePlanUsages < ActiveRecord::Migration[6.1]
  def change
    create_table :free_plan_usages do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, default: 'active'
      t.timestamps
    end
  end
end
