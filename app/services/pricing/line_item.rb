# frozen_string_literal: true

module Pricing
  # An item and a quantity, decoupled from ActiveRecord persistence.
  #
  # The calculator works on these rather than on OrderItem rows so a price can be
  # quoted before anything is written to the database.
  LineItem = Struct.new(:item, :quantity, keyword_init: true) do
    delegate :id, to: :item, prefix: true

    def unit_price
      item.price.to_f
    end
  end
end
