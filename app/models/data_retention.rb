# Collected phone and watch data is kept for DAYS local days (today plus the
# previous DAYS - 1) in each user's time zone; older rows are deleted by
# PurgeStaleDataJob and rejected as "skipped" by the upload API.
module DataRetention
  DAYS = ENV.fetch("DATA_RETENTION_DAYS", 7).to_i.clamp(1, 3650)

  # The column that decides a row's age.
  COLUMNS = {
    "AppUsageDay" => :date,
    "AppSession" => :ended_at,
    "ScreenEvent" => :occurred_at,
    "HealthSample" => :recorded_at,
    "SleepSession" => :ended_at
  }.freeze

  module_function

  # Start of the oldest day kept, in the current Time.zone.
  def cutoff
    (Date.current - (DAYS - 1)).beginning_of_day
  end

  def stale?(record)
    value = record.public_send(COLUMNS.fetch(record.class.name))
    return false if value.nil?

    value.is_a?(Date) ? value < cutoff.to_date : value < cutoff
  end

  # Deletes the user's stale rows; returns { "AppUsageDay" => count, … }.
  def purge!(user)
    Time.use_zone(user.time_zone) do
      boundary = cutoff
      COLUMNS.to_h do |model, column|
        limit = column == :date ? boundary.to_date : boundary
        [ model, model.constantize.where(user: user).where(column => ...limit).delete_all ]
      end
    end
  end
end
