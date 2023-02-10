# frozen_string_literal: true

# A "buy these two together" rule: when `item` and `discount_with_item` both
# appear in the same order, `percentage` is taken off `item`'s line.
#
# The rule is directional. To discount both sides of a pair, create two rows.
class Discount < ApplicationRecord
  belongs_to :item
  belongs_to :discount_with_item, class_name: 'Item', inverse_of: :unlocked_discounts

  validates :percentage, presence: true,
                         numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :paired_item_must_differ

  private

  def paired_item_must_differ
    return if item_id.blank? || discount_with_item_id.blank?
    return if item_id != discount_with_item_id

    errors.add(:discount_with_item_id, 'must be a different item')
  end
end
