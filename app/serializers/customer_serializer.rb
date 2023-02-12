# frozen_string_literal: true

class CustomerSerializer < ActiveModel::Serializer
  attributes :id, :name, :email
end
