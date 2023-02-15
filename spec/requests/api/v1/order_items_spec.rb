# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::OrderItems', type: :request do
  let(:order) { create(:order) }
  let(:item)  { create(:item, available_quantity: 3) }

  it 'adds a line to an existing order and takes the stock' do
    expect do
      post '/api/v1/order_items', params: { order_id: order.id, item_id: item.id, quantity: 2 }
    end.to change { item.reload.available_quantity }.from(3).to(1)

    expect(response).to have_http_status(:created)
  end

  # Regression: the stock callback raised RecordInvalid out of `save`, which
  # escaped the controller as a 500 instead of a 422.
  it 'returns 422, not 500, when the stock has gone' do
    post '/api/v1/order_items', params: { order_id: order.id, item_id: item.id, quantity: 99 }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_errors).to include(OrderItem::INSUFFICIENT_STOCK_MESSAGE)
  end

  it 'lists order items' do
    create(:order_item, order: order, item: item, quantity: 1)

    get '/api/v1/order_items'

    expect(response).to have_http_status(:ok)
    expect(json_body['order_items'].length).to eq(1)
  end
end
