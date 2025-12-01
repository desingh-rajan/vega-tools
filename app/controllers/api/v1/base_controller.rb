module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      # JWT authentication (will be implemented with devise-jwt)
      # before_action :authenticate_user!, except: [:public_endpoints]

      # Rescue from common errors
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found(exception)
        render json: {
          error: "Not Found",
          message: exception.message,
          status: 404
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "Unprocessable Entity",
          message: exception.record.errors.full_messages,
          status: 422
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          error: "Bad Request",
          message: exception.message,
          status: 400
        }, status: :bad_request
      end

      def render_success(data, status: :ok, meta: {})
        response = { data: data, status: "success" }
        response[:meta] = meta if meta.present?
        render json: response, status: status
      end

      def render_error(message, status: :bad_request, errors: nil)
        response = {
          error: message,
          status: "error"
        }
        response[:errors] = errors if errors.present?
        render json: response, status: status
      end

      # Pagination helpers
      def paginate(collection)
        page = (params[:page] || 1).to_i
        per_page = [ (params[:per_page] || 20).to_i, 100 ].min # Max 100 per page

        paginated = collection.limit(per_page).offset((page - 1) * per_page)

        {
          items: paginated,
          meta: {
            current_page: page,
            per_page: per_page,
            total_count: collection.count,
            total_pages: (collection.count.to_f / per_page).ceil
          }
        }
      end
    end
  end
end
