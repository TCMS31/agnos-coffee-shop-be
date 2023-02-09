class Customer < ApplicationRecord
  has_many :orders

  validates :email, presence: true, format: { with: EMAIL_PATTERN }
  validates :name, presence: true, uniqueness: { scope: %i[email] }
end
