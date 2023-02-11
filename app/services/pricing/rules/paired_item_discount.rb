# frozen_string_literal: true

module Pricing
  module Rules
    # "Buy a latte with a croissant and the croissant is 20% off."
    #
    # Applies at most one discount per line: the first matching rule wins, which
    # keeps the total deterministic when an item has several paired offers.
    # Discounts are read from the item's preloaded `discounts` association, so
    # this rule issues no queries of its own.
    class PairedItemDiscount
      def apply(unit_price, line_item, basket)
        discount = matching_discount(line_item, basket)
        return unit_price if discount.nil?

        unit_price - (unit_price * (discount.percentage.to_f / CoffeeShop::PERCENT_BASE))
      end

      private

      def matching_discount(line_item, basket)
        line_item.item.discounts.find do |discount|
          basket.include_item?(discount.discount_with_item_id)
        end
      end
    end
  end
end
