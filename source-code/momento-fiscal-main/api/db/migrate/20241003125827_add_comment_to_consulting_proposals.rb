class AddCommentToConsultingProposals < ActiveRecord::Migration[7.1]
  def change
    add_column :consulting_proposals, :comment, :string
  end
end
