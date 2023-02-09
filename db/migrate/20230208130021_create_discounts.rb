class CreateDiscounts < ActiveRecord::Migration[6.0]
  def change
    create_table :discounts do |t|
      t.integer :item_id, null: false
      t.integer :discount_with_item_id, null: false
      t.float :percentage

      t.timestamps
    end
  end
end
