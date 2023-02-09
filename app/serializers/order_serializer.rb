class OrderSerializer < ActiveModel::Serializer
  attributes :id, :total_amount

  belongs_to :customer
  has_many :items
end
