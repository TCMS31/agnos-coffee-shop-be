# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Items', type: :request do
  describe 'GET /api/v1/items' do
    it 'returns the menu under an "items" key' do
      create_list(:item, 2)

      get '/api/v1/items'

      expect(response).to have_http_status(:ok)
      expect(json_body['items'].length).to eq(2)
    end

    it 'exposes the fields the storefront renders' do
      create(:item, name: 'Latte', price: 4.0, tax_rate: 5.0, available_quantity: 12)

      get '/api/v1/items'

      expect(json_body['items'].first).to eq(
        'id' => Item.first.id, 'name' => 'Latte', 'price' => 4.0,
        'tax_rate' => 5.0, 'available_quantity' => 12
      )
    end

    it 'paginates' do
      create_list(:item, 3)

      get '/api/v1/items', params: { per_page: 1, page: 2 }

      expect(json_body['items'].length).to eq(1)
      expect(json_body['meta']).to include('page' => 2, 'total_count' => 3, 'total_pages' => 3)
    end
  end

  describe 'POST /api/v1/items' do
    it 'creates an item' do
      expect { post '/api/v1/items', params: { name: 'Bread', price: 24.99, tax_rate: 2.0 } }
        .to change(Item, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'rejects an item with no price' do
      post '/api/v1/items', params: { name: 'Bread' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors.join).to include('Price')
    end

    it 'rejects a negative price' do
      post '/api/v1/items', params: { name: 'Bread', price: -1 }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'ignores attributes that are not permitted' do
      post '/api/v1/items', params: { name: 'Bread', price: 1.0, id: 4242 }

      expect(Item.last.id).not_to eq(4242)
    end
  end

  describe 'PATCH /api/v1/items/:id' do
    it 'updates the item' do
      item = create(:item, price: 1.0)

      patch "/api/v1/items/#{item.id}", params: { price: 29.99 }

      expect(response).to have_http_status(:ok)
      expect(item.reload.price).to eq(29.99)
    end
  end

  describe 'DELETE /api/v1/items/:id' do
    it 'deletes an item nobody has ordered' do
      item = create(:item)

      expect { delete "/api/v1/items/#{item.id}" }.to change(Item, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'refuses to delete an item that appears on an order' do
      item = create(:item)
      create(:order_item, item: item, quantity: 1)

      delete "/api/v1/items/#{item.id}"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Item.exists?(item.id)).to be(true)
    end
  end
end
