items = (1..10).map do |index|
  { name: Faker::Food.dish,
    price: 19.99,
    tax_rate: Faker::Number.decimal(l_digits: 2),
    available_quantity: Faker::Number.number(digits: 2)
   }
end

Item.create(items)
item_ids = Item.where(name: items.pluck(:name)).ids

discounts = item_ids.first(5).map do |id|
  { item_id: id,
    discount_with_item_id: item_ids.last(5).sample,
    percentage: rand(1..99)
  }
end

Discount.create(discounts)
