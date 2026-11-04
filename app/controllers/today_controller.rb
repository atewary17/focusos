class TodayController < ApplicationController
  def show
    @now = Time.zone.now
    @day_number = (Date.current - Current.user.created_at.in_time_zone.to_date).to_i + 1
  end
end
