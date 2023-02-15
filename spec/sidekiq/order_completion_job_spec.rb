# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderCompletionJob do
  let(:order) { create(:order, notification_sent_at: nil) }

  before { create(:order_item, order: order, quantity: 1) }

  it 'sends the completion email' do
    expect { described_class.new.perform(order.id) }
      .to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it 'records when the notification went out' do
    expect { described_class.new.perform(order.id) }
      .to change { order.reload.notification_sent_at }.from(nil)
  end

  it 'does not send twice if the job is retried' do
    described_class.new.perform(order.id)

    expect { described_class.new.perform(order.id) }
      .not_to(change { ActionMailer::Base.deliveries.size })
  end

  it 'does nothing when the order has been deleted' do
    id = order.id
    order.destroy

    expect { described_class.new.perform(id) }.not_to raise_error
  end
end
