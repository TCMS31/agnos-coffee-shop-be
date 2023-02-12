# frozen_string_literal: true

# Liveness/readiness probe. Returns 200 only if the database answers, so a
# container orchestrator restarts an instance that has lost its connection
# rather than routing traffic to it.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok' }, status: :ok
  rescue StandardError => e
    render json: { status: 'error', errors: [e.message] }, status: :service_unavailable
  end
end
