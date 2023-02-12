# frozen_string_literal: true

module Api
  module V1
    # Generic JSON CRUD for a single ActiveRecord model.
    #
    # A subclass supplies two things -- which actions it exposes (`actions`) and
    # which attributes it accepts (`permitted_params`) -- and inherits
    # consistent serialization, pagination and error handling. The model and its
    # serializer are derived from the controller name, so `ItemsController`
    # drives `Item` through `ItemSerializer`.
    #
    # Collections are always paginated. `Model.all` with no limit is the first
    # thing that falls over once the shop has a year of orders in it.
    class BaseController < ApplicationController
      include BaseHandler
      include ExceptionHandler

      private

      def index
        render json: serialized_collection, status: :ok
      end

      def show
        render json: serialized_resource, status: :ok
      end

      def create
        if new_resource.save
          render json: new_resource, status: :created
        else
          render_error(new_resource)
        end
      end

      def update
        if resource.update(permitted_params)
          render json: resource, status: :ok
        else
          render_error(resource)
        end
      end

      def destroy
        return render_error(resource) unless resource.destroy

        head :no_content
      end

      # Overridden by subclasses that need to preload associations their
      # serializer touches, so an index is a fixed number of queries.
      def collection_scope
        model.all
      end

      def ordered_collection
        collection_scope.order(created_at: :desc, id: :desc)
      end

      def paginated_collection
        @paginated_collection ||= ordered_collection.limit(per_page).offset((page - 1) * per_page)
      end

      def resource
        @resource ||= collection_scope.find(params[:id])
      end

      def new_resource
        @new_resource ||= model.new(permitted_params)
      end

      def render_error(record)
        render_errors(record.errors.full_messages, :unprocessable_entity)
      end

      def model
        @model ||= controller_name.camelize.singularize.constantize
      end

      def serializer
        @serializer ||= "#{model}Serializer".constantize
      end

      def serialized_resource
        ActiveModelSerializers::SerializableResource.new(resource, serializer: serializer).as_json
      end

      def serialized_collection
        ActiveModelSerializers::SerializableResource.new(
          paginated_collection,
          each_serializer: serializer,
          adapter: :json,
          meta: pagination_meta
        ).as_json
      end

      def pagination_meta
        total = collection_scope.count
        {
          page: page,
          per_page: per_page,
          total_count: total,
          total_pages: per_page.positive? ? (total.to_f / per_page).ceil : 0
        }
      end

      def page
        @page ||= [params[:page].to_i, 1].max
      end

      def per_page
        @per_page ||= begin
          requested = params[:per_page].to_i
          requested = CoffeeShop::DEFAULT_PAGE_SIZE unless requested.positive?
          [requested, CoffeeShop::MAX_PAGE_SIZE].min
        end
      end
    end
  end
end
