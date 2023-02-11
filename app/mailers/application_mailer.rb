# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # A lambda, not `ENV['...']` directly: the class body runs once at boot, so a
  # literal read pinned whatever the value was at load time -- and when the
  # variable was unset it pinned `nil`, which made every delivery raise
  # "SMTP From address may not be blank". The fallback keeps the job working out
  # of the box; production should set EMAIL_DEFAULT_ADDRESS to a real sender.
  DEFAULT_FROM = 'no-reply@coffee-shop.example'

  default from: -> { ENV.fetch('EMAIL_DEFAULT_ADDRESS', DEFAULT_FROM) }
  layout 'mailer'
end
