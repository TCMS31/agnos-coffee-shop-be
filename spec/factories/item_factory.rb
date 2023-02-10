# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    name { Faker::Commerce.product_name }
    price { rand(0.0..100.0) }
    tax_rate { rand(0.0..1.0) }
    available_quantity { 5 }
  end
end