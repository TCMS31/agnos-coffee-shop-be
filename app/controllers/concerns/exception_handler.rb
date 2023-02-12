# frozen_string_literal: true

# Translates the exceptions the API can legitimately raise into JSON error
# bodies, so a client never sees an HTML error page or a bare 500.
#
# Every error response has the same shape: { "errors": ["...", "..."] }.
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do
      render_errors(['Record not found!'], :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_errors(e.record&.errors&.full_messages.presence || [e.message], :unprocessable_entity)
    end

    rescue_from ActiveRecord::RecordNotDestroyed do |e|
      render_errors(e.record&.errors&.full_messages.presence || [e.message], :unprocessable_entity)
    end

    rescue_from ActionController::ParameterMissing do |e|
      render_errors(["Missing required parameter: #{e.param}"], :bad_request)
    end
  end

  private

  def render_errors(messages, status)
    render json: { errors: Array(messages) }, status: status
  end
end
