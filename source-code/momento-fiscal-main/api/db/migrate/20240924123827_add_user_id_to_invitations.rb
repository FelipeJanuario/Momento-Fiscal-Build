class AddUserIdToInvitations < ActiveRecord::Migration[7.1]
  def change
    add_reference :invitations, :user, foreign_key: true, type: :uuid
  end
end
