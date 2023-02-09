module Api
  module V1
    class CustomersController < BaseController
      actions :index, :show, :create, :update, :destroy

      private

      def permitted_params
        params.permit(:name, :email)
      end
    end
  end
end
