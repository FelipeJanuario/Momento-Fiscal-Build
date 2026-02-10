class AddIsFavoriteToConsulting < ActiveRecord::Migration[7.1]
  def change
    add_column :consultings, :is_favorite, :boolean, default: false
  end
end
