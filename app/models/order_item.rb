class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item

  validates :quantity, presence: true
  validate :valid_quantity

  after_create :reduce_item_quantity

  private

  def valid_quantity
    errors.add(:base, "We don't have enough quantity for the items!") if item.available_quantity < quantity
  end

  def reduce_item_quantity
    item.update!(available_quantity: item.available_quantity - quantity)
  end
end
