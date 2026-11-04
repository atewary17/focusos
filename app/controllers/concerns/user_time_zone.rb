# Runs every request in the signed-in user's time zone, so Time.zone.now,
# Date.current and displayed timestamps match their local day.
# Data is always stored in UTC.
module UserTimeZone
  extend ActiveSupport::Concern

  included do
    around_action :use_user_time_zone
  end

  private
    def use_user_time_zone(&action)
      Time.use_zone(Current.user&.time_zone || User::DEFAULT_TIME_ZONE, &action)
    end
end
