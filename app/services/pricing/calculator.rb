# frozen_string_literal: true

require 'set'

module Pricing
  # Turns a basket of line items into a total.
  #
  # Pricing is a pipeline: each rule receives the running unit price and returns
  # a new one, in order. Adding a new kind of offer -- happy hour, loyalty tier,
  # buy-one-get-one -- means writing one class that responds to
  # `apply(unit_price, line_item, basket)` and putting it in the pipeline. No
  # existing rule, and nothing in the order service, has to change.
  #
  #   Pricing::Calculator.new(rules: [Rules::Tax.new, MyOffer.new])
  #
  # Order matters and is a deliberate business decision: tax is computed on the
  # shelf price first, then the discount is taken off the taxed figure.
  class Calculator
    def self.default_rules
      [Rules::Tax.new, Rules::PairedItemDiscount.new]
    end

    def initialize(rules: self.class.default_rules)
      @rules = rules
    end

    # @param line_items [Array<Pricing::LineItem>]
    # @return [Pricing::Quote]
    def quote(line_items)
      basket = Basket.new(line_items)
      lines = line_items.map { |line_item| price_line(line_item, basket) }
      Quote.new(lines)
    end

    private

    attr_reader :rules

    def price_line(line_item, basket)
      unit_price = @rules.reduce(line_item.unit_price) do |price, rule|
        rule.apply(price, line_item, basket)
      end

      Quote::Line.new(
        item_id: line_item.item_id,
        quantity: line_item.quantity,
        unit_price: round(unit_price),
        subtotal: round(unit_price * line_item.quantity)
      )
    end

    def round(amount)
      amount.round(CoffeeShop::CURRENCY_PRECISION)
    end
  end
end
