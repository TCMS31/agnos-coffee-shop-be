class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :tax_rate
end
