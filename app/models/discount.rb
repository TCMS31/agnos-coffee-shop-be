class Discount < ApplicationRecord
  belongs_to :item

  validates :discount_with_item_id, presence: true
end
