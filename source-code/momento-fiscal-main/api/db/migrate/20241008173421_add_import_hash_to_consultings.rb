class AddImportHashToConsultings < ActiveRecord::Migration[7.1]
  def change
    add_column :consultings, :import_hash, :string
    add_index :consultings, :import_hash, unique: true
    change_column_null :consultings, :client_id, true
  end
end
