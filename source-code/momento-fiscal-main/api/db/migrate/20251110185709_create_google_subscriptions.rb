class CreateGoogleSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :google_subscriptions, id: :uuid do |t|
      t.belongs_to :user, null: false, foreign_key: true, type: :uuid
      t.string :subscription_id
      t.string :purchase_token

      t.timestamps
    end
  end
end
