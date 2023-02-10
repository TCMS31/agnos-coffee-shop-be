# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  let(:customer) { create(:customer) }
  let(:order) { create(:order, customer: customer) }
  let(:item) { create(:item) }
  subject(:OrderItem) { create(:order_item, order: order, item: item) }

  describe 'associations' do
    it { should belong_to(:order) }
  end

  describe 'validations' do
    it 'validates the quantity of the items' do
      order_item = build(:order_item)
      order_item.item.available_quantity = 0

      order_item.valid?
      expect(order_item.errors.full_messages).to include("We don't have enough quantity for the items!")
    end
  end
end
