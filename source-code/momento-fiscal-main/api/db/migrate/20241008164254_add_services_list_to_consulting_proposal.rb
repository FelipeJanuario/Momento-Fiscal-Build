class AddServicesListToConsultingProposal < ActiveRecord::Migration[7.1]
  def change
    add_column :consulting_proposals, :services, :string

    remove_column :consulting_proposals, :passive_tax_management
    remove_column :consulting_proposals, :tax_planning
    remove_column :consulting_proposals, :bank_passive_reduction_management
    remove_column :consulting_proposals, :physical_assets_recovery
    remove_column :consulting_proposals, :business_reconstruction
  end
end
