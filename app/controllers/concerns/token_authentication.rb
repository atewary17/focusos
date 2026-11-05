# Bearer-token authentication for the JSON API. Never uses cookie sessions.
module TokenAuthentication
  extend ActiveSupport::Concern

  included do
    include ActionController::HttpAuthentication::Token::ControllerMethods
    before_action :require_token
  end

  class_methods do
    def allow_tokenless_access(**options)
      skip_before_action :require_token, **options
    end
  end

  private
    def require_token
      Current.api_token = authenticate_with_http_token { |plain, _options| ApiToken.authenticate(plain) }

      if Current.api_token
        Current.api_token.touch_last_used!
      else
        render_error "invalid_token", "Missing, invalid, expired or revoked token.", status: :unauthorized
      end
    end
end
