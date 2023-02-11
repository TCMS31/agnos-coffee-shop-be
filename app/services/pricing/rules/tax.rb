# frozen_string_literal: true

module Pricing
  module Rules
    # Adds the item's own tax rate to its unit price.
    #
    # Tax is applied per item, per the brief -- there is no single shop-wide VAT
    # rate, because a coffee and a takeaway sandwich are often taxed differently.
    class Tax
      def apply(unit_price, line_item, _basket)
        rate = line_item.item.tax_rate.to_f
        unit_price + (unit_price * (rate / CoffeeShop::PERCENT_BASE))
      end
    end
  end
end
