# frozen_string_literal: true

FactoryBot.define do
  factory :discount do
    item
    discount_with_item_id { create(:item).id }
    discount_percentage { rand(0.0..1.0) }
  end
end