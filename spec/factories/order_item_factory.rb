# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    association :order, factory: :order
    association :item, factory: :item
    quantity { 3 }
  end
end
