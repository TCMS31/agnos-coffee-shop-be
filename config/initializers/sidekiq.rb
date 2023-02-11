# frozen_string_literal: true

# Sidekiq defaults to redis://localhost:6379/0. Naming REDIS_URL explicitly keeps
# the dependency visible and lets the container compose file point at the
# `redis` service without any code change.
redis_config = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
