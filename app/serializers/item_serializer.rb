# frozen_string_literal: true

class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :tax_rate, :available_quantity
end
