module Api
  module V1
    class BaseController < ApplicationController
      include BaseHandler
      include ExceptionHandler

      def index
        render json: serialized_resources, status: :ok
      end

      def show
        render json: serialized_resource, status: :ok
      end

      def create
        if new_resource.save
          render json: new_resource, status: :created
        else
          render json: { message: new_resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if resource.update(permitted_params)
          render_resource
        else
          render_error
        end
      end

      def destroy
        render_error unless resource.destroy
      end

      def resources
        @resources ||= model.all.order(created_at: :desc)
      end

      def resource
        @resources ||= model.find(params[:id])
      end

      def new_resource
        @new_resource ||= model.new(permitted_params)
      end

      def render_resource
        render json: resource, status: :ok
      end

      def render_error
        render json: { message: resource.errors.full_messages }, status: :unprocessable_entity
      end

      def model
        @model ||= controller_name.camelize.singularize.constantize
      end

      def serialized_resource
        serializer.new(resource).to_json
      end

      def serialized_resources
        serialize(resources, serializer)
      end

      def serializer
        @serializer ||= "#{model}Serializer".constantize
      end

      def serialize(collection, serializer)
        ActiveModelSerializers::SerializableResource.new(collection,
                                                         each_serializer: serializer,
                                                         adapter: :json
                                                        )
                                                    .as_json
      end
    end
  end
end
