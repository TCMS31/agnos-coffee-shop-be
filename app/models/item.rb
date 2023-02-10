# frozen_string_literal: true

# Something the shop sells. `price` is the shelf price before tax; `tax_rate` is
# a percentage (7.5 means 7.5%), and `available_quantity` is the stock on hand.
class Item < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items
  # Discounts this item can receive when bought alongside another item.
  has_many :discounts, dependent: :destroy
  # Discounts on *other* items that this item unlocks. Needed so deleting an
  # item cannot leave a discount pointing at a row that no longer exists.
  has_many :unlocked_discounts, class_name: 'Discount',
                                foreign_key: :discount_with_item_id,
                                inverse_of: :discount_with_item,
                                dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :available_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
