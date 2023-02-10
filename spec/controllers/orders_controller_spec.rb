# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  describe 'POST #create' do
    let!(:customer) { create(:customer) }
    let(:item) { create(:item) }
    let(:valid_params) do
      {
        customer: { name: customer.name, email: customer.email },
        order_items: [{ item_id: item.id, quantity: 1 }]
      }
    end

    context 'with valid params' do
      it 'creates a new order' do
        expect { post :create, params: valid_params }.to change(Order, :count).by(1)
      end

      it 'responds with 200' do
        post :create, params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    let!(:orders) { create_list(:order, 3) }

    it 'returns a list of orders' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['orders'].length).to eq(3)
    end
  end

  describe 'GET #show' do
    let(:order) { create(:order) }

    it 'returns a order' do
      get :show, params: { id: order.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(order.id)
    end
  end

  describe 'DELETE #destroy' do
    let!(:order) { create(:order) }

    it 'deletes the order' do
      expect { delete :destroy, params: { id: order.id } }.to change(Order, :count).by(-1)
    end

    it 'responds with 200' do
      delete :destroy, params: { id: order.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end
