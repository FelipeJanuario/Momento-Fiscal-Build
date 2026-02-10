class CreateConsultingProposals < ActiveRecord::Migration[7.1]
  def change
    create_table :consulting_proposals, id: :uuid do |t|
      t.references :consulting, null: false, foreign_key: true, type: :bigint

      t.boolean :passive_tax_management, default: true
      t.boolean :tax_planning, default: true
      t.boolean :bank_passive_reduction_management, default: true
      t.boolean :physical_assets_recovery, default: true
      t.boolean :business_reconstruction, default: true

      t.text :description

      t.timestamps
    end
  end
end
