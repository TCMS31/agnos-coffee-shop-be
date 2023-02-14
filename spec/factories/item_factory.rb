# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "#{Faker::Commerce.product_name} #{n}" }
    price { 10.0 }
    tax_rate { 0.0 }
    available_quantity { 5 }
  end
end
