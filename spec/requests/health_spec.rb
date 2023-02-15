# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health', type: :request do
  it 'reports ok when the database answers' do
    get '/up'

    expect(response).to have_http_status(:ok)
    expect(json_body).to eq('status' => 'ok')
  end

  it 'reports unavailable when the database does not' do
    allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'down')

    get '/up'

    expect(response).to have_http_status(:service_unavailable)
    expect(json_body['errors']).to eq(['down'])
  end
end
