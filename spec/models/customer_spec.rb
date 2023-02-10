#frozen_literal_literal: true

require 'rails_helper'

RSpec.describe Customer, type: :model do
  it { should have_many(:orders) }

  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:name) }
end
