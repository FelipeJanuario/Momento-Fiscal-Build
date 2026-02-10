class AddIosPlanToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :ios_plan, :boolean, default: false, null: false
  end
end
