# frozen_string_literal: true

module Pricing
  # The priced result of a basket: per-line figures plus the order total.
  #
  # Every figure is rounded to whole cents before it is summed, so the total a
  # customer is charged always equals the sum of the lines they can see.
  class Quote
    Line = Struct.new(:item_id, :quantity, :unit_price, :subtotal, keyword_init: true)

    attr_reader :lines

    def initialize(lines)
      @lines = lines.freeze
    end

    def total
      lines.sum(&:subtotal).round(CoffeeShop::CURRENCY_PRECISION)
    end
  end
end
