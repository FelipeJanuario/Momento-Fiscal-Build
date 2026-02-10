class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title
      t.string :content
      t.string :redirect_to
      t.time :read_at

      t.timestamps
    end
  end
end
