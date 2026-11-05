module Api
  module V1
    class BaseController < ActionController::API
      MAX_BODY_BYTES = 1.megabyte
      REQUESTS_PER_HOUR = 120
      # Own store so limits also apply in development and test (Rails.cache is a null store there).
      RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

      before_action :reject_oversized_body
      include TokenAuthentication
      include UserTimeZone

      # One budget per device across all API endpoints (per IP before sign-in).
      rate_limit to: REQUESTS_PER_HOUR, within: 1.hour, store: RATE_LIMIT_STORE, scope: "api/v1",
                 by: -> { Current.device&.id || request.remote_ip },
                 with: -> { render_error "rate_limited", "Too many requests. Try again later.", status: :too_many_requests }

      rescue_from ActionController::ParameterMissing do |error|
        render_error "validation_failed", error.message, status: 422
      end

      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error "validation_failed", error.record.errors.full_messages.to_sentence, status: 422
      end

      rescue_from ActionDispatch::Http::Parameters::ParseError do
        render_error "invalid_json", "The request body is not valid JSON.", status: :bad_request
      end

      private
        def render_error(code, message, status:, details: nil)
          render json: { error: { code: code, message: message, details: details }.compact }, status: status
        end

        def reject_oversized_body
          if request.content_length.to_i > MAX_BODY_BYTES
            render_error "payload_too_large", "Request body must be at most 1 MB.", status: 413
          end
        end

        def require_device
          render_error "device_required", "This token is not linked to a device.", status: :forbidden unless Current.device
        end
    end
  end
end
