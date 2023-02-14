# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
    it { is_expected.to have_many(:items).through(:order_items) }
  end

  describe '#notified?' do
    it 'is false until the completion mail has gone out' do
      expect(build(:order, notification_sent_at: nil)).not_to be_notified
    end

    it 'is true once the timestamp is set' do
      expect(build(:order, notification_sent_at: Time.current)).to be_notified
    end
  end

  describe '.recent_first' do
    it 'returns the newest order first' do
      older = create(:order, created_at: 2.days.ago)
      newer = create(:order, created_at: 1.hour.ago)

      expect(described_class.recent_first.to_a).to eq([newer, older])
    end
  end

  it 'takes its order items with it when destroyed' do
    order = create(:order)
    create(:order_item, order: order, quantity: 1)

    expect { order.destroy }.to change(OrderItem, :count).by(-1)
  end
end
