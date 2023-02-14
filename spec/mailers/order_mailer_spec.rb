# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderMailer, type: :mailer do
  subject(:mail) { described_class.completion_notification(order) }

  let(:customer) { create(:customer, name: 'ada lovelace', email: 'ada@example.com') }
  let(:order)    { create(:order, customer: customer, total_amount: 12.5) }
  let(:item)     { create(:item, name: 'Flat White') }

  before { create(:order_item, order: order, item: item, quantity: 2) }

  it 'is addressed to the customer' do
    expect(mail.to).to eq(['ada@example.com'])
  end

  # Regression: `default from: ENV['EMAIL_DEFAULT_ADDRESS']` was read once at
  # class load, so with the variable unset every delivery raised
  # "SMTP From address may not be blank".
  it 'falls back to a sender address when EMAIL_DEFAULT_ADDRESS is unset' do
    expect(mail.from).to eq([ApplicationMailer::DEFAULT_FROM])
  end

  it 'uses EMAIL_DEFAULT_ADDRESS when it is set' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('EMAIL_DEFAULT_ADDRESS', anything).and_return('hi@shop.test')

    expect(described_class.completion_notification(order).from).to eq(['hi@shop.test'])
  end

  it 'has the expected subject' do
    expect(mail.subject).to eq('Thank you for placing order with us!')
  end

  it 'greets the customer by name' do
    expect(mail.body.encoded).to include('Ada Lovelace')
  end

  it 'lists the ordered item and how many' do
    expect(mail.body.encoded).to include('Flat White')
    expect(mail.body.encoded).to include('2')
  end

  it 'shows the total to two decimal places' do
    expect(mail.body.encoded).to include('12.50')
  end

  # Regression: the mailer used to write notification_sent_at itself, so simply
  # rendering a preview marked the order as notified.
  it 'does not mark the order as notified' do
    expect { mail.body }.not_to(change { order.reload.notification_sent_at })
  end
end
