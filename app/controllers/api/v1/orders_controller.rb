module Api
  module V1
    class OrdersController < BaseController
      actions :index, :show, :destroy

      def create
        order = OrderProcessingService.call(customer_params, order_items_params[:order_items])

        render json: order, status: order[:status].eql?('error') ? :unprocessable_entity : :ok
      end

      private

      def customer_params
        params.require(:customer).permit(:name, :email)
      end

      def order_items_params
        params.permit(order_items: [:item_id, :quantity])
      end
    end
  end
end
