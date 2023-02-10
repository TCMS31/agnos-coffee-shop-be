# frozen_string_literal: true

# A person who has placed at least one order.
#
# Customers are identified by the (name, email) pair, which is uniquely indexed:
# a returning customer reuses their existing row rather than accumulating
# duplicates. Emails are normalised on the way in so "Ada@Example.COM " and
# "ada@example.com" are the same customer.
class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true, format: { with: CoffeeShop::EMAIL_PATTERN }
  validates :name, presence: true, uniqueness: { scope: %i[email] }

  # Call sites that look a customer up by email (OrderProcessingService) must
  # normalise the same way, or the lookup misses and the unique index rejects
  # the insert.
  def self.normalize_email(value)
    value.to_s.strip.downcase.presence
  end

  private

  def normalize_email
    self.email = self.class.normalize_email(email)
  end
end
