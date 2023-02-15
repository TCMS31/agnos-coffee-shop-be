# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Customers', type: :request do
  describe 'GET /api/v1/customers' do
    it 'returns the customers under a "customers" key' do
      create_list(:customer, 2)

      get '/api/v1/customers'

      expect(response).to have_http_status(:ok)
      expect(json_body['customers'].length).to eq(2)
      expect(json_body['customers'].first.keys).to match_array(%w[id name email])
    end
  end

  describe 'POST /api/v1/customers' do
    it 'creates a customer' do
      expect { post '/api/v1/customers', params: { name: 'Demo', email: 'name@example.com' } }
        .to change(Customer, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'rejects a malformed email' do
      post '/api/v1/customers', params: { name: 'Demo', email: 'nope' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_errors.join).to include('Email is invalid')
    end
  end

  describe 'DELETE /api/v1/customers/:id' do
    it 'takes the customer orders with it' do
      customer = create(:customer)
      create(:order, customer: customer)

      expect { delete "/api/v1/customers/#{customer.id}" }.to change(Order, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
