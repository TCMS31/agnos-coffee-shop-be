# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    customer
    total_amount { 0.0 }
    notification_sent_at { nil }
  end
end
