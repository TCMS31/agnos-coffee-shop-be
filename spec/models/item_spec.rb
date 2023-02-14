# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item, type: :model do
  subject { build(:item) }

  describe 'associations' do
    it { is_expected.to have_many(:order_items) }
    it { is_expected.to have_many(:orders).through(:order_items) }
    it { is_expected.to have_many(:discounts).dependent(:destroy) }
    it { is_expected.to have_many(:unlocked_discounts).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }

    it 'rejects a negative price' do
      expect(build(:item, price: -1)).not_to be_valid
    end

    it 'rejects negative stock' do
      expect(build(:item, available_quantity: -1)).not_to be_valid
    end
  end

  describe 'deleting an item that has been ordered' do
    it 'is refused rather than orphaning the order line' do
      item = create(:item)
      create(:order_item, item: item, quantity: 1)

      expect(item.destroy).to be(false)
      expect(item.errors.full_messages.join).to match(/Cannot delete/i)
    end
  end

  describe 'deleting an item that only has discounts' do
    it 'takes the discounts with it, both directions' do
      item = create(:item)
      create(:discount, item: item)
      create(:discount, discount_with_item: item)

      expect { item.destroy }.to change(Discount, :count).by(-2)
    end
  end
end
