# frozen_string_literal: true

require 'rails_helper'

# Regression: `resources :discounts` has been routed since the first commit, but
# Api::V1::DiscountsController did not exist, so every one of these requests
# raised "A route matches, but references missing controller".
RSpec.describe 'Api::V1::Discounts', type: :request do
  let(:croissant) { create(:item) }
  let(:latte)     { create(:item) }

  describe 'GET /api/v1/discounts' do
    it 'lists the paired discounts' do
      create(:discount, item: croissant, discount_with_item: latte, percentage: 20.0)

      get '/api/v1/discounts'

      expect(response).to have_http_status(:ok)
      expect(json_body['discounts'].first).to include(
        'item_id' => croissant.id, 'discount_with_item_id' => latte.id, 'percentage' => 20.0
      )
    end
  end

  describe 'POST /api/v1/discounts' do
    it 'creates a paired discount' do
      expect do
        post '/api/v1/discounts', params: { item_id: croissant.id,
                                            discount_with_item_id: latte.id,
                                            percentage: 15.0 }
      end.to change(Discount, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'rejects a percentage above 100' do
      post '/api/v1/discounts', params: { item_id: croissant.id,
                                          discount_with_item_id: latte.id,
                                          percentage: 150 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors.join).to include('Percentage')
    end

    it 'rejects pairing an item with itself' do
      post '/api/v1/discounts', params: { item_id: croissant.id,
                                          discount_with_item_id: croissant.id,
                                          percentage: 10 }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'a created discount changes what an order costs' do
    it 'is applied by the next order that buys the pair' do
      cheap = create(:item, price: 10.0, tax_rate: 0.0, available_quantity: 5)
      pair  = create(:item, price: 10.0, tax_rate: 0.0, available_quantity: 5)
      post '/api/v1/discounts', params: { item_id: cheap.id,
                                          discount_with_item_id: pair.id,
                                          percentage: 50.0 }

      post '/api/v1/orders', params: {
        customer: { name: 'Ada', email: 'ada@example.com' },
        order_items: [{ item_id: cheap.id, quantity: 1 }, { item_id: pair.id, quantity: 1 }]
      }

      expect(json_body['total_amount']).to eq(15.0)
    end
  end

  describe 'DELETE /api/v1/discounts/:id' do
    it 'deletes the discount' do
      discount = create(:discount)

      expect { delete "/api/v1/discounts/#{discount.id}" }.to change(Discount, :count).by(-1)
    end
  end
end
