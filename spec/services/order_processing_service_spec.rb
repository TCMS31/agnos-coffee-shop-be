# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderProcessingService do
  let(:latte)     { create(:item, name: 'Latte', price: 4.00, tax_rate: 5.0, available_quantity: 10) }
  let(:croissant) { create(:item, name: 'Croissant', price: 3.00, tax_rate: 10.0, available_quantity: 10) }
  let(:customer_params) { { name: 'Ada', email: 'ada@example.com' } }

  def place(items, customer: customer_params)
    described_class.call(customer, items)
  end

  describe 'a successful order' do
    it 'creates the order' do
      expect { place([{ item_id: latte.id, quantity: 2 }]) }.to change(Order, :count).by(1)
    end

    it 'reports success' do
      expect(place([{ item_id: latte.id, quantity: 1 }])).to be_success
    end

    it 'stores the tax-inclusive total' do
      result = place([{ item_id: latte.id, quantity: 2 }])

      expect(result.order.total_amount).to eq(8.4) # (4.00 + 5%) * 2
    end

    it 'prices a mixed basket' do
      result = place([{ item_id: latte.id, quantity: 1 }, { item_id: croissant.id, quantity: 1 }])

      expect(result.order.total_amount).to eq(7.5) # 4.20 + 3.30
    end

    it 'applies a paired discount' do
      create(:discount, item: croissant, discount_with_item: latte, percentage: 50.0)

      result = place([{ item_id: latte.id, quantity: 1 }, { item_id: croissant.id, quantity: 1 }])

      expect(result.order.total_amount).to eq(5.85) # 4.20 + (3.30 / 2)
    end

    it 'takes the stock' do
      expect { place([{ item_id: latte.id, quantity: 3 }]) }
        .to change { latte.reload.available_quantity }.from(10).to(7)
    end

    it 'schedules the completion notification' do
      expect { place([{ item_id: latte.id, quantity: 1 }]) }
        .to change(OrderCompletionJob.jobs, :size).by(1)
    end

    it 'schedules it for ten minutes out' do
      freeze_time = Time.current
      allow(Time).to receive(:now).and_return(freeze_time)

      place([{ item_id: latte.id, quantity: 1 }])

      delay = OrderCompletionJob.jobs.last['at'] - freeze_time.to_f
      expect(delay).to be_within(1).of(CoffeeShop::ORDER_COMPLETION_DELAY_SECONDS)
    end

    it 'reuses a returning customer rather than duplicating them' do
      create(:customer, name: 'Ada', email: 'ada@example.com')

      expect { place([{ item_id: latte.id, quantity: 1 }]) }.not_to change(Customer, :count)
    end

    it 'matches a returning customer whose address is cased differently' do
      existing = create(:customer, name: 'Ada', email: 'ada@example.com')

      result = place([{ item_id: latte.id, quantity: 1 }],
                     customer: { name: 'Ada', email: 'ADA@Example.com ' })

      expect(result.order.customer).to eq(existing)
    end
  end

  describe 'a rejected order' do
    it 'refuses an empty basket' do
      result = place([])

      expect(result).not_to be_success
      expect(result.errors).to include(described_class::MISSING_ORDER_ITEMS)
    end

    it 'refuses a nil basket' do
      expect(place(nil).errors).to include(described_class::MISSING_ORDER_ITEMS)
    end

    it 'refuses an unknown item' do
      result = place([{ item_id: 999_999, quantity: 1 }])

      expect(result).not_to be_success
      expect(result.errors).to include(described_class::UNKNOWN_ITEM)
    end

    it 'refuses an invalid email' do
      result = place([{ item_id: latte.id, quantity: 1 }],
                     customer: { name: 'Ada', email: 'nope' })

      expect(result).not_to be_success
      expect(result.errors.join).to include('Email is invalid')
    end

    it 'refuses to oversell' do
      result = place([{ item_id: latte.id, quantity: 11 }])

      expect(result.errors).to include(OrderItem::INSUFFICIENT_STOCK_MESSAGE)
    end

    it 'leaves no order behind when a later line fails' do
      expect do
        place([{ item_id: latte.id, quantity: 1 }, { item_id: croissant.id, quantity: 99 }])
      end.not_to change(Order, :count)
    end

    it 'gives back the stock taken by the lines that did succeed' do
      expect do
        place([{ item_id: latte.id, quantity: 1 }, { item_id: croissant.id, quantity: 99 }])
      end.not_to(change { latte.reload.available_quantity })
    end

    it 'does not schedule a notification' do
      expect { place([]) }.not_to change(OrderCompletionJob.jobs, :size)
    end
  end

  describe 'query count' do
    # Pricing loads the items and their discounts in two queries regardless of
    # basket size; before that it was one query per line plus one per line's
    # discounts.
    it 'does not grow the item/discount queries with basket size' do
      items = create_list(:item, 5, price: 1.0, tax_rate: 0.0, available_quantity: 50)
      lines = items.map { |item| { item_id: item.id, quantity: 1 } }

      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        if payload[:sql].start_with?('SELECT') && payload[:sql].include?('"discounts"')
          queries << payload[:sql]
        end
      end
      place(lines)
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(queries.size).to eq(1)
    end
  end

  describe 'rule injection' do
    it 'prices with the calculator it is handed' do
      result = described_class.call(customer_params,
                                    [{ item_id: latte.id, quantity: 1 }],
                                    calculator: Pricing::Calculator.new(rules: []))

      expect(result.order.total_amount).to eq(4.0) # untaxed
    end
  end
end
