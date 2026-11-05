class Current < ActiveSupport::CurrentAttributes
  # Web requests set `session` (cookie); API requests set `api_token` (bearer token).
  attribute :session, :api_token

  def user
    session&.user || api_token&.user
  end

  def device
    api_token&.device
  end
end
