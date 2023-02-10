# frozen_string_literal: true

# A single till transaction. `total_amount` is the tax-inclusive, discount-applied
# figure computed by OrderProcessingService at the moment the order is placed --
# it is deliberately a snapshot, so later price changes never rewrite history.
class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :items, through: :order_items

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def notified?
    notification_sent_at.present?
  end
end
