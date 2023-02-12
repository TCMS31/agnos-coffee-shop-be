# frozen_string_literal: true

class OrderSerializer < ActiveModel::Serializer
  attributes :id, :total_amount, :created_at

  belongs_to :customer
  has_many :items
end
