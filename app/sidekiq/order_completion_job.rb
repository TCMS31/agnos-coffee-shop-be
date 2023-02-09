class OrderCompletionJob
  include Sidekiq::Job

  def perform(id)
    order = Order.find_by_id(id)
    return if order.nil? || order.notification_sent_at.present?

    OrderMailer.completion_notification(order).deliver_now
  end
end
