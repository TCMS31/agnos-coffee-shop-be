# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:item) }
  end

  describe 'validations' do
    it 'refuses to sell more than the shop has' do
      item = create(:item, available_quantity: 2)
      order_item = build(:order_item, item: item, quantity: 3)

      expect(order_item).not_to be_valid
      expect(order_item.errors.full_messages).to include(described_class::INSUFFICIENT_STOCK_MESSAGE)
    end

    it 'allows ordering exactly the remaining stock' do
      item = create(:item, available_quantity: 2)

      expect(build(:order_item, item: item, quantity: 2)).to be_valid
    end

    # Regression: `valid_quantity` used to call `item.available_quantity`
    # unguarded, so an unknown item_id raised NoMethodError (a 500) instead of
    # failing validation.
    it 'fails validation instead of raising when the item does not exist' do
      order_item = build(:order_item, item: nil, item_id: 999_999, quantity: 1)

      expect { order_item.valid? }.not_to raise_error
      expect(order_item.errors[:item]).to be_present
    end

    # Regression: quantity had a presence check only, so -3 passed validation
    # and the stock callback *added* three units back to the shelf.
    it 'rejects a zero quantity' do
      expect(build(:order_item, quantity: 0)).not_to be_valid
    end

    it 'rejects a negative quantity' do
      order_item = build(:order_item, quantity: -3)

      expect(order_item).not_to be_valid
      expect(order_item.errors[:quantity]).to be_present
    end
  end

  describe 'stock' do
    it 'takes the ordered quantity off the shelf' do
      item = create(:item, available_quantity: 5)

      expect { create(:order_item, item: item, quantity: 2) }
        .to change { item.reload.available_quantity }.from(5).to(3)
    end

    it 'refreshes the in-memory item after the decrement' do
      item = create(:item, available_quantity: 5)
      order_item = create(:order_item, item: item, quantity: 2)

      expect(order_item.item.available_quantity).to eq(3)
    end

    # The decrement is a single conditional UPDATE, so a line that slips past
    # the (non-locking) validation still cannot drive stock negative.
    it 'refuses the write when the stock has gone since validation' do
      item = create(:item, available_quantity: 5)
      order_item = build(:order_item, item: item, quantity: 5)
      order_item.validate

      # rubocop:disable-next Rails/SkipsModelValidations -- simulating a concurrent write.
      Item.where(id: item.id).update_all(available_quantity: 1)

      expect { order_item.save! }.to raise_error(ActiveRecord::RecordInvalid,
                                                 /#{described_class::INSUFFICIENT_STOCK_MESSAGE}/)
      expect(item.reload.available_quantity).to eq(1)
    end
  end
end
