# frozen_string_literal: true

# Sends the "your order is ready" email, ten minutes after the order is placed.
#
# The job owns the `notification_sent_at` bookkeeping rather than the mailer:
# marking the order before delivery keeps a retried job from mailing the
# customer twice, and a mailer that quietly mutates a record is a surprise
# waiting for the next reader.
class OrderCompletionJob
  include Sidekiq::Job

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.nil? || order.notified?

    # `update!` first: if two workers pick the same job up, the second sees the
    # timestamp and returns without sending.
    order.update!(notification_sent_at: Time.current)
    OrderMailer.completion_notification(order).deliver_now
  end
end
