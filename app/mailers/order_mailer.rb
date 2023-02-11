# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def completion_notification(order)
    @customer = order.customer
    @order_items = order.order_items.includes(:item)
    @total_amount = order.total_amount

    mail(to: @customer.email, subject: 'Thank you for placing order with us!')
  end
end
