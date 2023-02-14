# frozen_string_literal: true

FactoryBot.define do
  factory :discount do
    item
    association :discount_with_item, factory: :item
    percentage { 20.0 }
  end
end
