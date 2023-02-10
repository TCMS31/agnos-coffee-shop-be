# frozen_string_literal: true

# One line on an order: an item and how many of it.
#
# Stock is taken here rather than in the service so that *every* route to
# creating a line (the orders endpoint, the order_items endpoint, the console)
# goes through the same check. The validation gives a friendly 422 for the
# common case; the conditional UPDATE in `reduce_item_quantity` is what actually
# makes the decrement safe under concurrency.
class OrderItem < ApplicationRecord
  INSUFFICIENT_STOCK_MESSAGE = "We don't have enough quantity for the items!"

  belongs_to :order
  belongs_to :item

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validate :sufficient_stock

  after_create :reduce_item_quantity

  private

  def sufficient_stock
    return if item.blank? || quantity.blank?
    return unless quantity.is_a?(Numeric)
    return if item.available_quantity >= quantity

    errors.add(:base, INSUFFICIENT_STOCK_MESSAGE)
  end

  # Conditional UPDATE: the `available_quantity >= ?` predicate is evaluated by
  # the database under the row lock it takes for the write, so two concurrent
  # orders for the last croissant cannot both succeed. A plain
  # `item.update!(available_quantity: item.available_quantity - quantity)`
  # read-modify-writes in Ruby and oversells.
  def reduce_item_quantity
    # rubocop:disable Rails/SkipsModelValidations -- bypassing validations is the
    # point: the guard is the WHERE clause, evaluated atomically by the database.
    updated = Item.where(id: item_id)
                  .where(available_quantity: quantity..)
                  .update_all(['available_quantity = available_quantity - ?', quantity])
    # rubocop:enable Rails/SkipsModelValidations

    if updated.zero?
      errors.add(:base, INSUFFICIENT_STOCK_MESSAGE)
      raise ActiveRecord::RecordInvalid, self
    end

    # Reflect the decrement in the in-memory copy instead of paying for a
    # re-read: the UPDATE above changed exactly this much and nothing else.
    item.available_quantity -= quantity
    item.changes_applied
  end
end
