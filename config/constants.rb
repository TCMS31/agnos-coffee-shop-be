# frozen_string_literal: true

# Application-wide constants.
#
# Loaded from `config/application.rb` before Bundler.require, so nothing here may
# depend on Rails or ActiveSupport being present yet (hence plain integers rather
# than `10.minutes`).
module CoffeeShop
  # Deliberately permissive: this is a shop till, not an identity provider. It
  # rejects the obvious typos without bouncing valid-but-unusual addresses.
  EMAIL_PATTERN = /\A[^@\s]+@[^@\s]+\.[^@\s]{2,}\z/.freeze

  # Collection endpoints are always paginated; an unbounded `Model.all` is the
  # first thing to fall over once the shop has real traffic.
  DEFAULT_PAGE_SIZE = 25
  MAX_PAGE_SIZE = 100

  # How long after an order is placed the "your order is ready" mail goes out.
  ORDER_COMPLETION_DELAY_SECONDS = 10 * 60

  # Percentages are stored as 0..100, not 0..1.
  PERCENT_BASE = 100.0

  # Money is rounded to whole cents at every step so float drift never reaches
  # the customer.
  CURRENCY_PRECISION = 2
end
