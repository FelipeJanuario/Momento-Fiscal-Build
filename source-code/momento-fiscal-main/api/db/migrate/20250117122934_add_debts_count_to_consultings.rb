class AddDebtsCountToConsultings < ActiveRecord::Migration[7.1]
  def change
    add_column :consultings, :debts_count, :integer
  end
end
