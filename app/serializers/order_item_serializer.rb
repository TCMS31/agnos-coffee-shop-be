# frozen_string_literal: true

class OrderItemSerializer < ActiveModel::Serializer
  attributes :id, :order_id, :item_id, :quantity
end
