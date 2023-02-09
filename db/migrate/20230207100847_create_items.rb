class CreateItems < ActiveRecord::Migration[6.0]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.float :price, null: false
      t.float :tax_rate, default: 0.0
      t.integer :available_quantity, default: 0

      t.timestamps
    end
  end
end
