# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'
require 'sidekiq/testing'

# Jobs are pushed to an in-memory array instead of Redis, so the suite has no
# external service dependency and can assert on what *would* have been enqueued.
Sidekiq::Testing.fake!

# Support files (shared examples, helpers) are loaded explicitly.
Rails.root.glob('spec/support/**/*.rb').sort.each { |file| require file }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = Rails.root.join('spec/fixtures').to_s
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ApiResponseHelpers, type: :request
  config.include ApiResponseHelpers, type: :controller

  config.before do
    Sidekiq::Job.clear_all
    ActionMailer::Base.deliveries.clear
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
