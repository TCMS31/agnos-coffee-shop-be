# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Orders', type: :request do
  let(:item) { create(:item, price: 10.0, tax_rate: 0.0, available_quantity: 10) }

  describe 'POST /api/v1/orders' do
    let(:valid_payload) do
      {
        customer: { name: 'Ada', email: 'ada@example.com' },
        order_items: [{ item_id: item.id, quantity: 2 }]
      }
    end

    it 'creates the order' do
      expect { post '/api/v1/orders', params: valid_payload }.to change(Order, :count).by(1)
    end

    it 'responds 201' do
      post '/api/v1/orders', params: valid_payload

      expect(response).to have_http_status(:created)
    end

    it 'returns the customer, the items and the total the frontend renders' do
      post '/api/v1/orders', params: valid_payload

      expect(json_body).to include('id', 'total_amount')
      expect(json_body['customer']).to include('name' => 'Ada', 'email' => 'ada@example.com')
      expect(json_body['items'].pluck('id')).to eq([item.id])
      expect(json_body['total_amount']).to eq(20.0)
    end

    it 'rejects a basket with no items' do
      post '/api/v1/orders', params: { customer: { name: 'Ada', email: 'ada@example.com' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors).to include(OrderProcessingService::MISSING_ORDER_ITEMS)
    end

    it 'rejects an unknown item with 422 rather than 500' do
      post '/api/v1/orders', params: {
        customer: { name: 'Ada', email: 'ada@example.com' },
        order_items: [{ item_id: 999_999, quantity: 1 }]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors).to include(OrderProcessingService::UNKNOWN_ITEM)
    end

    it 'rejects an order for more than the shop has' do
      post '/api/v1/orders', params: {
        customer: { name: 'Ada', email: 'ada@example.com' },
        order_items: [{ item_id: item.id, quantity: 999 }]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors).to include(OrderItem::INSUFFICIENT_STOCK_MESSAGE)
    end

    it 'reports a missing customer block as a bad request' do
      post '/api/v1/orders', params: { order_items: [{ item_id: item.id, quantity: 1 }] }

      expect(response).to have_http_status(:bad_request)
      expect(json_errors.join).to include('customer')
    end
  end

  describe 'GET /api/v1/orders' do
    it 'returns the orders under an "orders" key' do
      create_list(:order, 3)

      get '/api/v1/orders'

      expect(response).to have_http_status(:ok)
      expect(json_body['orders'].length).to eq(3)
    end

    it 'paginates and reports the page in meta' do
      create_list(:order, 3)

      get '/api/v1/orders', params: { per_page: 2 }

      expect(json_body['orders'].length).to eq(2)
      expect(json_body['meta']).to include('page' => 1, 'per_page' => 2,
                                           'total_count' => 3, 'total_pages' => 2)
    end

    it 'caps per_page so a client cannot ask for the whole table' do
      get '/api/v1/orders', params: { per_page: 10_000 }

      expect(json_body['meta']['per_page']).to eq(CoffeeShop::MAX_PAGE_SIZE)
    end

    it 'returns the newest order first' do
      older = create(:order, created_at: 2.days.ago)
      newer = create(:order, created_at: 1.minute.ago)

      get '/api/v1/orders'

      expect(json_body['orders'].pluck('id')).to eq([newer.id, older.id])
    end

    it 'loads customers and items without an N+1' do
      3.times { create(:order_item, quantity: 1) }

      counts = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        counts << payload[:sql] unless payload[:name] == 'SCHEMA'
      end
      get '/api/v1/orders'
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(counts.size).to be <= 6
    end
  end

  describe 'GET /api/v1/orders/:id' do
    it 'returns the order' do
      order = create(:order)

      get "/api/v1/orders/#{order.id}"

      expect(response).to have_http_status(:ok)
      expect(json_body['id']).to eq(order.id)
    end

    it 'returns a JSON 404 for an unknown id' do
      get '/api/v1/orders/999999'

      expect(response).to have_http_status(:not_found)
      expect(json_errors).to eq(['Record not found!'])
    end
  end

  describe 'DELETE /api/v1/orders/:id' do
    it 'deletes the order' do
      order = create(:order)

      expect { delete "/api/v1/orders/#{order.id}" }.to change(Order, :count).by(-1)
    end

    it 'responds 204' do
      order = create(:order)

      delete "/api/v1/orders/#{order.id}"

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PATCH /api/v1/orders/:id' do
    # A placed order is a priced snapshot; there is deliberately no update route,
    # so a client cannot rewrite total_amount after the fact.
    it 'is not routable' do
      order = create(:order, total_amount: 42.0)

      expect { patch "/api/v1/orders/#{order.id}", params: { total_amount: 0 } }
        .to raise_error(ActionController::RoutingError)
      expect(order.reload.total_amount).to eq(42.0)
    end
  end
end
