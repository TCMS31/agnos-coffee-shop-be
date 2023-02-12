# frozen_string_literal: true

module Api
  module V1
    class OrderItemsController < BaseController
      actions :index, :show, :create, :destroy

      private

      def collection_scope
        OrderItem.includes(:item)
      end

      def permitted_params
        params.permit(:order_id, :item_id, :quantity)
      end
    end
  end
end
