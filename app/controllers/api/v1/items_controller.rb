module Api
  module V1
    class ItemsController < BaseController
      actions :index, :show, :create, :update, :destroy

      private

      def permitted_params
        params.permit(:name, :price, :tax_rate, :available_quantity)
      end
    end
  end
end
