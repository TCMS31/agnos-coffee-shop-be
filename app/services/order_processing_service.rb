# frozen_string_literal: true

# Places an order: resolves the customer, writes the lines, takes the stock,
# prices the basket and schedules the "your order is ready" email.
#
# The whole write is one transaction -- a basket that fails on its third line
# leaves no half-order and no stock taken. Pricing is delegated to
# Pricing::Calculator, which is injectable so a caller (or a test) can price an
# order with a different set of rules.
class OrderProcessingService
  # Raised for problems with the request itself rather than with a record.
  class InvalidRequest < StandardError; end

  MISSING_ORDER_ITEMS = 'Order items are required!'
  UNKNOWN_ITEM = 'One or more of the requested items do not exist.'

  # The outcome of an attempt to place an order. Callers ask `success?` rather
  # than type-checking the return value.
  class Result
    attr_reader :order, :errors

    def self.success(order)
      new(order: order)
    end

    def self.failure(errors)
      new(errors: errors)
    end

    def initialize(order: nil, errors: [])
      @order = order
      @errors = Array(errors)
    end

    def success?
      errors.empty?
    end
  end

  def self.call(customer_data, order_items_data, calculator: Pricing::Calculator.new)
    new(customer_data, order_items_data, calculator: calculator).process_order
  end

  def initialize(customer_data, order_items_data, calculator: Pricing::Calculator.new)
    @customer_data = customer_data
    @order_items_data = order_items_data
    @calculator = calculator
  end

  def process_order
    lines = requested_lines
    items = load_items(lines)
    order = place(lines, items)

    schedule_completion_notification(order)
    Result.success(order)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(error_messages(e))
  rescue InvalidRequest => e
    Result.failure([e.message])
  end

  private

  attr_reader :customer_data, :order_items_data, :calculator

  def place(lines, items)
    order = nil

    ActiveRecord::Base.transaction do
      order = customer.orders.create!
      # Hand the already-loaded Item objects to the association rather than bare
      # ids: `belongs_to` verifies the item exists, and an id would make it
      # issue one SELECT per line to do so.
      order.order_items.create!(lines.map { |line| line_attributes(line, items) })
      order.update!(total_amount: total_for(lines, items))
    end

    order
  end

  def line_attributes(line, items)
    { item: items[line[:item_id].to_i], quantity: line[:quantity] }
  end

  def requested_lines
    raise InvalidRequest, MISSING_ORDER_ITEMS if order_items_data.blank?

    order_items_data.map do |attributes|
      { item_id: attributes[:item_id], quantity: attributes[:quantity] }
    end
  end

  # Two queries total (items, then their discounts) however many lines the order
  # has. Loading up front also lets an unknown item fail before anything is
  # written, and is what keeps the pricing rules free of their own queries.
  def load_items(lines)
    ids = lines.filter_map { |line| line[:item_id].presence&.to_i }.uniq
    items = Item.where(id: ids).includes(:discounts).index_by(&:id)
    raise InvalidRequest, UNKNOWN_ITEM unless (ids - items.keys).empty?

    items
  end

  def total_for(lines, items)
    line_items = lines.filter_map do |line|
      item = items[line[:item_id].to_i]
      next if item.nil?

      Pricing::LineItem.new(item: item, quantity: line[:quantity].to_i)
    end

    calculator.quote(line_items).total
  end

  def customer
    @customer ||= find_or_create_customer
  end

  def find_or_create_customer
    attributes = {
      name: customer_data[:name],
      email: Customer.normalize_email(customer_data[:email])
    }

    Customer.find_or_create_by!(attributes)
  rescue ActiveRecord::RecordNotUnique
    # Two requests for the same new customer raced; the other one won.
    Customer.find_by!(attributes)
  end

  def schedule_completion_notification(order)
    OrderCompletionJob.perform_in(CoffeeShop::ORDER_COMPLETION_DELAY_SECONDS, order.id)
  end

  def error_messages(exception)
    messages = exception.record&.errors&.full_messages
    messages.presence || [exception.message]
  end
end
