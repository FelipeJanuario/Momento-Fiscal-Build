# frozen_string_literal: true

class AddSourceToDividasCaches < ActiveRecord::Migration[7.2]
  def change
    # Cria a tabela dividas_caches se não existir
    unless table_exists?(:dividas_caches)
      create_table :dividas_caches do |t|
        t.string :cnpj, null: false, limit: 14
        t.integer :debt_count, default: 0
        t.decimal :debt_value, precision: 15, scale: 2, default: 0.0
        t.jsonb :dados, default: {}
        t.datetime :checked_at
        t.string :source, default: "serpro", null: false

        t.timestamps
      end

      add_index :dividas_caches, [:cnpj, :source], unique: true
      add_index :dividas_caches, :source
    end
  end
end
