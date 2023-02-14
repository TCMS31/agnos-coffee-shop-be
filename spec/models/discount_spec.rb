# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Discount, type: :model do
  subject { build(:discount) }

  describe 'associations' do
    it { is_expected.to belong_to(:item) }
    it { is_expected.to belong_to(:discount_with_item).class_name('Item') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:percentage) }

    it 'rejects a percentage over 100' do
      expect(build(:discount, percentage: 101)).not_to be_valid
    end

    it 'rejects a zero percentage' do
      expect(build(:discount, percentage: 0)).not_to be_valid
    end

    it 'refuses to pair an item with itself' do
      item = create(:item)
      discount = build(:discount, item: item, discount_with_item: item)

      expect(discount).not_to be_valid
      expect(discount.errors[:discount_with_item_id]).to include('must be a different item')
    end
  end

  it 'builds from the factory' do
    expect(create(:discount)).to be_persisted
  end
end
