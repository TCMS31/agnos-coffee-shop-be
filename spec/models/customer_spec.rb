# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customer, type: :model do
  subject { build(:customer) }

  describe 'associations' do
    it { is_expected.to have_many(:orders).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:email) }

    it 'rejects an address without a domain' do
      customer = build(:customer, email: 'not-an-email')

      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to include('is invalid')
    end

    it 'accepts a conventional address' do
      expect(build(:customer, email: 'ada@example.co.uk')).to be_valid
    end
  end

  describe 'email normalisation' do
    it 'strips and downcases on the way in' do
      customer = create(:customer, email: '  Ada@Example.COM ')

      expect(customer.email).to eq('ada@example.com')
    end

    it 'treats a differently-cased address as the same customer' do
      create(:customer, name: 'Ada', email: 'ada@example.com')
      duplicate = build(:customer, name: 'Ada', email: 'ADA@example.com')

      expect(duplicate).not_to be_valid
    end

    it 'exposes the same rule to callers that look customers up' do
      expect(described_class.normalize_email(' Ada@Example.COM ')).to eq('ada@example.com')
    end
  end
end
