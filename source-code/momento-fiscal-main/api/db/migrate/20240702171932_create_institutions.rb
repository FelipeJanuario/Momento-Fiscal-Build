class CreateInstitutions < ActiveRecord::Migration[7.1]
  def change
    create_table :institutions, id: :uuid do |t|
      t.string :cnpj, null: false, limit: 14
      t.string :responsible_name, null: false
      t.string :responsible_cpf, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :cell_phone, null: false
      t.decimal :limit_debt, null: false, precision: 10, scale: 2

      t.timestamps
    end

    add_index :institutions, :cnpj, unique: true
  end
end
