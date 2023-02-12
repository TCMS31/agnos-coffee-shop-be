# frozen_string_literal: true

# Opt-in exposure of the CRUD actions inherited from Api::V1::BaseController.
#
# BaseController declares its actions private, so a subclass is closed by
# default and lists what it actually offers:
#
#   class ItemsController < BaseController
#     actions :index, :show, :create, :update, :destroy
#   end
#
# A route that reaches an action the controller never opted into raises
# AbstractController::ActionNotFound rather than quietly working -- which is how
# `PATCH /api/v1/orders/:id` used to reach a generic update it was never meant
# to have.
module BaseHandler
  extend ActiveSupport::Concern

  class_methods do
    def actions(*names)
      public(*names)
    end
  end
end
