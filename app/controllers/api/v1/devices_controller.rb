module Api
  module V1
    class DevicesController < BaseController
      MIN_APP_VERSION = ENV.fetch("ANDROID_MIN_APP_VERSION", "0.1.0")

      before_action :require_device

      # Sent by the app at the end of every sync.
      def heartbeat
        report = params.permit(:app_version, permissions: [ :usage_access, :battery_exempt, { health_connect: [] } ], summary: {})

        Current.device.update!(
          app_version: report[:app_version].presence || Current.device.app_version,
          permissions: report[:permissions]&.to_h || {},
          last_sync_summary: report[:summary]&.to_h || {},
          last_sync_at: Time.current
        )

        render json: { server_time: Time.current.utc.iso8601, min_app_version: MIN_APP_VERSION }
      end
    end
  end
end
