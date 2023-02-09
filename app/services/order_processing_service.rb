class OrderProcessingService
  attr_reader :customer_data, :order_items_data

  def self.call(customer_data, order_items_data)
    new(customer_data, order_items_data).process_order
  end

  def initialize(customer_data, order_items_data)
    @customer_data = customer_data
    @order_items_data = order_items_data
  end

  def process_order
    ActiveRecord::Base.transaction do
      customer = Customer.find_or_create_by(@customer_data)
      order = customer.orders.create!
      order_items = order.order_items.create!(@order_items_data)

      if order.update(total_amount: calculate_total_price(order_items))
        send_notification(order) && order
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    { status: 'error', message: e.record.errors.full_messages.to_sentence }
  end

  def calculate_total_price(order_items)
    total = 0.0
    ordered_item_ids = order_items.pluck(:item_id)
    order_items.each do |order_item|
      total += (order_item.quantity * item_price(order_item.item, ordered_item_ids))
    end
    total
  end

  def item_price(item, ordered_item_ids)
    price = item.price + (item.price * (item.tax_rate/ 100))

    item.discounts.each do |discount|
      next unless discount.discount_with_item_id.in? ordered_item_ids

      price -= (price * (discount.percentage / 100))
      break
    end

    price
  end

  def send_notification(order)
    OrderCompletionJob.perform_in(10.minutes.from_now, order.id)
  end
end
