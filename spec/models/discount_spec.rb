#frozen_literal_literal: true

require 'rails_helper'

RSpec.describe Discount, type: :model do
  it { should belong_to(:item) }
end