# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    order
    item
    quantity { 1 }
  end
end
