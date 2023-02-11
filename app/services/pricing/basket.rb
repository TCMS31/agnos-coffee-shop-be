# frozen_string_literal: true

module Pricing
  # The read-only context a rule is allowed to look at: every line in the order.
  #
  # Rules ask the basket questions ("is item 7 also in this order?") instead of
  # reaching back into the database, which is what keeps the calculator free of
  # N+1 queries.
  class Basket
    attr_reader :line_items

    def initialize(line_items)
      @line_items = line_items.freeze
    end

    def item_ids
      @item_ids ||= line_items.to_set(&:item_id)
    end

    def include_item?(item_id)
      item_ids.include?(item_id)
    end
  end
end
