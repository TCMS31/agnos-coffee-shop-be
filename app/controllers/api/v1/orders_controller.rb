# frozen_string_literal: true

module Api
  module V1
    class OrdersController < BaseController
      actions :index, :show, :destroy

      # Placing an order is not a generic `Order.create` -- it resolves the
      # customer, takes stock, prices the basket and schedules a notification --
      # so it delegates to OrderProcessingService rather than to BaseController.
      def create
        result = OrderProcessingService.call(customer_params, order_items_params[:order_items])

        if result.success?
          render json: result.order, status: :created
        else
          render_errors(result.errors, :unprocessable_entity)
        end
      end

      private

      # The serializer renders the customer and the ordered items, so both are
      # preloaded: an index of 25 orders is 3 queries, not 51.
      def collection_scope
        Order.includes(:customer, :items)
      end

      def customer_params
        params.require(:customer).permit(:name, :email)
      end

      def order_items_params
        params.permit(order_items: %i[item_id quantity])
      end
    end
  end
end
