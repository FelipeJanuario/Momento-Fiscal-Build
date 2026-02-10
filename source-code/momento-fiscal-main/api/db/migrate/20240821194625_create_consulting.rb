class CreateConsulting < ActiveRecord::Migration[7.1]
  def change
    create_table :consultings do |t|
      t.integer :status, default: 0, null: false
      t.decimal :value, precision: 15, scale: 2, null: false
      t.time :sent_at, null: false
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :consultant, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
