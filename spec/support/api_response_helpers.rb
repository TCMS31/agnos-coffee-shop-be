# frozen_string_literal: true

# Small conveniences shared by request and controller specs.
module ApiResponseHelpers
  def json_body
    JSON.parse(response.body)
  end

  def json_errors
    json_body.fetch('errors')
  end
end
