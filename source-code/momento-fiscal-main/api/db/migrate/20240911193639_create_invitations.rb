class CreateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :invitations, id: :uuid do |t|
      t.string :email
      t.integer :status, default: 0
      t.datetime :sent_at

      t.timestamps
    end
    
    add_index :invitations, :email, unique: true
  end
end
