class CreateUserInstitutions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_institutions, id: :uuid do |t|
      t.integer :role, default: 0, null: false
      t.belongs_to :user, null: false, foreign_key: true, type: :uuid
      t.belongs_to :institution, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
