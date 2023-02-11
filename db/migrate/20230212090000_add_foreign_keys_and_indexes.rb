# frozen_string_literal: true

# The original schema declared the join columns `null: false` but never indexed
# them and never constrained them, so:
#
#   * every `order.order_items` / `item.discounts` lookup was a sequential scan,
#     which is what made pricing an order O(table) rather than O(basket); and
#   * an item could be deleted out from under the orders that referenced it.
#
# CHECK constraints (available_quantity >= 0, quantity > 0) would be the natural
# belt-and-braces here, but Rails 6.0's Ruby schema format cannot round-trip
# them: they would survive `db:migrate` and vanish on `db:schema:load`, which is
# worse than not having them. The oversell invariant is held instead by the
# conditional UPDATE in OrderItem#reduce_item_quantity, which is atomic in the
# database, plus the model validations.
class AddForeignKeysAndIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :orders, :customer_id
    add_index :orders, :created_at
    add_index :order_items, :order_id
    add_index :order_items, :item_id
    add_index :discounts, :item_id
    add_index :discounts, :discount_with_item_id

    add_foreign_key :orders, :customers
    add_foreign_key :order_items, :orders
    add_foreign_key :order_items, :items
    add_foreign_key :discounts, :items
    add_foreign_key :discounts, :items, column: :discount_with_item_id
  end
end
