module Api
  module V1
    class OrderItemsController < BaseController
      actions :index, :show, :create, :update, :destroy

      private

      def permitted_params
        params.permit(:name, :order_id, :item_id, :quantity)
      end
    end
  end
end
