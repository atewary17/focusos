module Api
  module V1
    # Sign-in for the Android app: email + password → a bearer token for this device.
    class TokensController < BaseController
      allow_tokenless_access only: :create
      rate_limit to: 10, within: 3.minutes, only: :create, store: RATE_LIMIT_STORE, name: "sign-in",
                 with: -> { render_error "rate_limited", "Too many sign-in attempts. Try again in a few minutes.", status: :too_many_requests }

      def create
        user = User.authenticate_by(email_address: params[:email_address].to_s, password: params[:password].to_s)
        return render_error("invalid_credentials", "Email or password is wrong.", status: :unauthorized) unless user

        attributes = params.expect(device: [ :installation_id, *Device::SIGN_IN_ATTRIBUTES ])
        token = nil

        device = user.devices.find_or_initialize_by(installation_id: attributes[:installation_id])
        Device.transaction do
          device.update!(attributes.except(:installation_id))
          # One active token per device: signing in again replaces the old one.
          device.api_tokens.active.update_all(revoked_at: Time.current)
          _record, token = ApiToken.issue!(user: user, device: device, name: device.name)
        end

        render json: { token: token, user: { name: user.name, time_zone: user.time_zone }, device_id: device.id },
               status: :created
      end

      def destroy
        Current.api_token.revoke!
        head :no_content
      end
    end
  end
end
