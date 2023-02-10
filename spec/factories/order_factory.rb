# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :customer, factory: :customer
    total_amount { rand(0.0..1000.0) }
    notification_sent_at { Time.now }
  end
end
