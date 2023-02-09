class OrderMailer < ApplicationMailer
  def completion_notification(order)
    return if order.notification_sent_at.present?

    @customer = order.customer
    @items = order.items
    @total_amount = order.total_amount

    order.update(notification_sent_at: Time.current)
    mail(to: @customer.email, subject: 'Thank you for placing order with us!')
  end
end
