# frozen_string_literal: true

class DiscountSerializer < ActiveModel::Serializer
  attributes :id, :item_id, :discount_with_item_id, :percentage
end
