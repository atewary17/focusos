# JSON requests against /api/v1 with a bearer token from test/fixtures/api_tokens.yml.
module ApiHelper
  def api_post(path, params = {}, token: "fo_test_one")
    post path, params: params, headers: auth_header(token), as: :json
  end

  def auth_header(token)
    token ? { "Authorization" => "Bearer #{token}" } : {}
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include ApiHelper
  setup { Api::V1::BaseController::RATE_LIMIT_STORE.clear }
end
