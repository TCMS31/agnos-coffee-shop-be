# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pricing::Calculator do
  def line(item, quantity)
    Pricing::LineItem.new(item: item, quantity: quantity)
  end

  describe 'tax' do
    it 'adds the item tax rate to the shelf price' do
      item = create(:item, price: 10.0, tax_rate: 10.0)

      expect(described_class.new.quote([line(item, 1)]).total).to eq(11.0)
    end

    it 'multiplies by quantity' do
      item = create(:item, price: 10.0, tax_rate: 10.0)

      expect(described_class.new.quote([line(item, 3)]).total).to eq(33.0)
    end

    it 'taxes each item at its own rate' do
      coffee = create(:item, price: 4.0, tax_rate: 5.0)   # 4.20
      food   = create(:item, price: 8.0, tax_rate: 12.5)  # 9.00

      expect(described_class.new.quote([line(coffee, 1), line(food, 1)]).total).to eq(13.2)
    end
  end

  describe 'paired discounts' do
    let(:croissant) { create(:item, price: 10.0, tax_rate: 0.0) }
    let(:latte)     { create(:item, price: 5.0, tax_rate: 0.0) }

    before { create(:discount, item: croissant, discount_with_item: latte, percentage: 20.0) }

    it 'leaves the price alone when the paired item is absent' do
      expect(described_class.new.quote([line(croissant, 1)]).total).to eq(10.0)
    end

    it 'takes the percentage off when both items are in the basket' do
      total = described_class.new.quote([line(croissant, 1), line(latte, 1)]).total

      expect(total).to eq(13.0) # 8.00 + 5.00
    end

    it 'is directional: the paired item is not itself discounted' do
      quote = described_class.new.quote([line(croissant, 1), line(latte, 1)])
      latte_line = quote.lines.find { |l| l.item_id == latte.id }

      expect(latte_line.unit_price).to eq(5.0)
    end

    it 'applies the discount to the taxed price, not the shelf price' do
      taxed = create(:item, price: 10.0, tax_rate: 10.0)
      create(:discount, item: taxed, discount_with_item: latte, percentage: 20.0)

      quote = described_class.new.quote([line(taxed, 1), line(latte, 1)])
      taxed_line = quote.lines.find { |l| l.item_id == taxed.id }

      expect(taxed_line.unit_price).to eq(8.8) # 10 -> 11.00 -> 8.80
    end

    it 'applies at most one discount per line' do
      other = create(:item, price: 1.0, tax_rate: 0.0)
      create(:discount, item: croissant, discount_with_item: other, percentage: 50.0)

      quote = described_class.new.quote([line(croissant, 1), line(latte, 1), line(other, 1)])
      croissant_line = quote.lines.find { |l| l.item_id == croissant.id }

      expect(croissant_line.unit_price).to eq(8.0)
    end
  end

  describe 'rounding' do
    it 'rounds every line to whole cents so the total matches the visible lines' do
      item = create(:item, price: 0.333, tax_rate: 0.0)

      quote = described_class.new.quote([line(item, 3)])

      expect(quote.lines.first.unit_price).to eq(0.33)
      expect(quote.total).to eq(quote.lines.sum(&:subtotal))
    end
  end

  describe 'the rule pipeline' do
    it 'runs exactly the rules it is given' do
      item = create(:item, price: 10.0, tax_rate: 50.0)

      expect(described_class.new(rules: []).quote([line(item, 1)]).total).to eq(10.0)
    end

    # The extension seam: a new kind of offer is one class with #apply.
    it 'accepts a rule the application does not ship' do
      flat_two_off = Class.new do
        def apply(unit_price, _line_item, _basket)
          unit_price - 2
        end
      end
      item = create(:item, price: 10.0, tax_rate: 0.0)

      total = described_class.new(rules: [flat_two_off.new]).quote([line(item, 2)]).total

      expect(total).to eq(16.0)
    end
  end

  it 'prices an empty basket as zero' do
    expect(described_class.new.quote([]).total).to eq(0)
  end
end
