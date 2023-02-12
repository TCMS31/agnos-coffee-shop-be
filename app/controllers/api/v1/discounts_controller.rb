# frozen_string_literal: true

module Api
  module V1
    # "Apply discounts on a pair of items bought together" is part of the brief,
    # and `config/routes.rb` has always routed /api/v1/discounts -- but the
    # controller behind it was never written, so every request to it raised
    # `uninitialized constant Api::V1::DiscountsController`.
    class DiscountsController < BaseController
      actions :index, :show, :create, :update, :destroy

      private

      def collection_scope
        Discount.includes(:item, :discount_with_item)
      end

      def permitted_params
        params.permit(:item_id, :discount_with_item_id, :percentage)
      end
    end
  end
end
