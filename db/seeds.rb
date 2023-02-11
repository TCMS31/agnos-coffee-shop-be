# frozen_string_literal: true

# Seed data for a working demo. Idempotent: running it twice updates the same
# rows rather than duplicating the menu.
#
# It deliberately uses no Faker -- Faker lives in the development/test bundle, so
# a Faker-based seed file cannot run in production, which is exactly where you
# most want to seed a menu.

MENU = [
  { name: 'Espresso',           price: 2.50,  tax_rate: 5.0,  available_quantity: 200 },
  { name: 'Flat White',         price: 3.80,  tax_rate: 5.0,  available_quantity: 150 },
  { name: 'Cold Brew',          price: 4.20,  tax_rate: 5.0,  available_quantity: 80 },
  { name: 'Butter Croissant',   price: 3.10,  tax_rate: 12.5, available_quantity: 40 },
  { name: 'Almond Danish',      price: 3.60,  tax_rate: 12.5, available_quantity: 25 },
  { name: 'Avocado Sourdough',  price: 7.95,  tax_rate: 12.5, available_quantity: 30 },
  { name: 'Blueberry Muffin',   price: 2.95,  tax_rate: 12.5, available_quantity: 35 }
].freeze

# item -> paired item -> percentage off the item when both are in one order.
PAIRED_DISCOUNTS = [
  ['Butter Croissant',  'Flat White', 20.0],
  ['Almond Danish',     'Espresso',   15.0],
  ['Blueberry Muffin',  'Cold Brew',  10.0]
].freeze

items = MENU.each_with_object({}) do |attributes, acc|
  item = Item.find_or_initialize_by(name: attributes[:name])
  item.update!(attributes)
  acc[attributes[:name]] = item
end

PAIRED_DISCOUNTS.each do |name, paired_name, percentage|
  discount = Discount.find_or_initialize_by(
    item_id: items.fetch(name).id,
    discount_with_item_id: items.fetch(paired_name).id
  )
  discount.update!(percentage: percentage)
end

Rails.logger.debug { "Seeded #{Item.count} items and #{Discount.count} paired discounts." }
