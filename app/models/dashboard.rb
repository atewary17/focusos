# Numbers for /dashboard, from the data the Android collector uploads, in the
# user's time zone. Every figure is a plain sum, count, average or minimum, so
# each one can be explained in one sentence on the page.
class Dashboard
  INSTAGRAM = "com.instagram.android".freeze
  YOUTUBE = "com.google.android.youtube".freeze
  # Android counts the home screen and system UI as foreground time; they aren't app use.
  SYSTEM_PACKAGE = /launcher|systemui/i

  # Display groups for Health Connect sleep stages, in stacking order (bottom first).
  SLEEP_GROUPS = { "deep" => "Deep", "light" => "Light", "rem" => "REM",
                   "asleep" => "Asleep, no stage", "awake" => "Awake" }.freeze
  STAGE_TO_GROUP = { "deep" => "deep", "light" => "light", "rem" => "rem",
                     "sleeping" => "asleep", "unknown" => "asleep",
                     "awake" => "awake", "awake_in_bed" => "awake", "out_of_bed" => "awake" }.freeze

  attr_reader :days, :dates, :today

  # Covers the whole retention window; older data no longer exists.
  def initialize(user, today: Date.current)
    @user = user
    @days = DataRetention::DAYS
    @today = today
    @dates = ((today - (@days - 1))..today).to_a
  end

  def any_data?
    @user.devices.exists?
  end

  def last_sync
    @user.devices.where.not(last_sync_at: nil).order(last_sync_at: :desc).first
  end

  # ---------------------------------------------------------------- phone

  # { date => { instagram:, youtube:, other: } } in minutes.
  def app_minutes_by_day
    @app_minutes_by_day ||= begin
      totals = dates.index_with { { instagram: 0.0, youtube: 0.0, other: 0.0 } }
      usage_seconds.each do |(package, date), seconds|
        key = { INSTAGRAM => :instagram, YOUTUBE => :youtube }.fetch(package, :other)
        totals[date][key] += seconds / 60.0 if totals.key?(date)
      end
      totals.transform_values { |parts| parts.transform_values(&:round) }
    end
  end

  def screen_minutes(date)
    app_minutes_by_day.fetch(date, {}).values.sum
  end

  # Average over the earlier days in the range that have any app time.
  def average_screen_minutes
    earlier = dates[0...-1].map { |date| screen_minutes(date) }.select(&:positive?)
    (earlier.sum / earlier.size.to_f).round if earlier.any?
  end

  def top_apps(limit: 8)
    totals = Hash.new(0)
    usage_seconds.each { |(package, _date), seconds| totals[package] += seconds }
    totals.sort_by { |_package, seconds| -seconds }.first(limit).map do |package, seconds|
      { package_name: package, label: label_for(package), minutes: (seconds / 60.0).round }
    end
  end

  # { date => [minutes in hour 0, …, hour 23] } from app sessions, split at hour boundaries.
  def hourly_minutes
    @hourly_minutes ||= begin
      grid = dates.index_with { Array.new(24, 0.0) }
      @user.app_sessions.where(started_at: ..range_end, ended_at: range_start..)
           .pluck(:package_name, :started_at, :ended_at).each do |package, started_at, ended_at|
        next if package.match?(SYSTEM_PACKAGE)

        time = [ started_at, range_start ].max.in_time_zone
        finish = [ ended_at, range_end ].min.in_time_zone
        while time < finish
          boundary = [ time.beginning_of_hour + 1.hour, finish ].min
          grid[time.to_date][time.hour] += (boundary - time) / 60.0 if grid.key?(time.to_date)
          time = boundary
        end
      end
      grid.transform_values { |hours| hours.map(&:round) }
    end
  end

  # Unlocks per day.
  def pickups_by_day
    @pickups_by_day ||= begin
      counts = daily(@user.screen_events.where(kind: "unlock"), :occurred_at, "COUNT(*)")
      dates.index_with { |date| counts[date].to_i }
    end
  end

  # ---------------------------------------------------------------- body

  def steps_by_day
    @steps_by_day ||= begin
      sums = daily(health("steps"), :recorded_at, "SUM(value)")
      dates.index_with { |date| sums[date].to_i }
    end
  end

  # { date => { low:, average: } } for days with heart-rate readings.
  def heart_rate_by_day
    @heart_rate_by_day ||= health("heart_rate").where(recorded_at: range_start..range_end)
      .group(Arel.sql(local_date(:recorded_at)))
      .pluck(Arel.sql(local_date(:recorded_at)), Arel.sql("MIN(value)"), Arel.sql("AVG(value)"))
      .to_h { |date, low, average| [ date, { low: low.round, average: average.round } ] }
  end

  # Average heart rate per 15 minutes over the last 24 hours: [[time, bpm], …].
  def heart_rate_last_24_hours(now: Time.current)
    bucket = "FLOOR(EXTRACT(EPOCH FROM recorded_at) / 900) * 900"
    health("heart_rate").where(recorded_at: (now - 24.hours)..now)
      .group(Arel.sql(bucket)).order(Arel.sql(bucket))
      .pluck(Arel.sql(bucket), Arel.sql("AVG(value)"))
      .map { |epoch, average| [ Time.zone.at(epoch.to_i), average.round ] }
  end

  # { average:, low: } for the last 24 hours, or nil without readings.
  def spo2_last_24_hours(now: Time.current)
    average, low = health("spo2").where(recorded_at: (now - 24.hours)..now).pick(Arel.sql("AVG(value)"), Arel.sql("MIN(value)"))
    { average: average.round, low: low.round } if average
  end

  # Nights keyed by the date the user woke up:
  # { date => { minutes: { "deep" => …, … }, asleep_minutes:, bedtime:, wake: } }
  def sleep_by_night
    @sleep_by_night ||= begin
      nights = {}
      @user.sleep_sessions.where(ended_at: range_start..range_end).order(:started_at).each do |session|
        night = nights[session.ended_at.in_time_zone.to_date] ||=
          { minutes: SLEEP_GROUPS.keys.index_with { 0.0 }, bedtime: session.started_at, wake: session.ended_at }
        night[:wake] = session.ended_at
        stage_minutes(session).each { |group, minutes| night[:minutes][group] += minutes }
      end
      nights.transform_values do |night|
        asleep = night[:minutes].except("awake").values.sum
        night.merge(minutes: night[:minutes].transform_values(&:round), asleep_minutes: asleep.round)
      end
    end
  end

  private
    def range_start
      dates.first.beginning_of_day
    end

    def range_end
      today.end_of_day
    end

    def usage_seconds
      @usage_seconds ||= @user.app_usage_days.where(date: dates).group(:package_name, :date).sum(:foreground_seconds)
                              .reject { |(package, _date), _seconds| package.match?(SYSTEM_PACKAGE) }
    end

    def label_for(package)
      @labels ||= @user.app_usage_days.where(date: dates).where.not(app_label: nil).pluck(:package_name, :app_label).to_h
      @labels[package].presence || package
    end

    def health(kind)
      @user.health_samples.where(kind: kind)
    end

    # { local date => aggregate } for rows whose `column` falls in the range.
    def daily(scope, column, aggregate)
      scope.where(column => range_start..range_end)
           .group(Arel.sql(local_date(column)))
           .pluck(Arel.sql(local_date(column)), Arel.sql(aggregate)).to_h
    end

    # SQL for a UTC timestamp column's date in the user's time zone.
    def local_date(column)
      zone = ActiveRecord::Base.connection.quote(Time.zone.tzinfo.name)
      "(#{ActiveRecord::Base.connection.quote_column_name(column)} AT TIME ZONE 'UTC' AT TIME ZONE #{zone})::date"
    end

    # Minutes per display group; a session without stages counts as "asleep".
    def stage_minutes(session)
      return { "asleep" => (session.ended_at - session.started_at) / 60.0 } if session.stages.blank?

      session.stages.each_with_object(Hash.new(0.0)) do |stage, minutes|
        group = STAGE_TO_GROUP.fetch(stage["stage"], "asleep")
        minutes[group] += (Time.iso8601(stage["end"]) - Time.iso8601(stage["start"])) / 60.0
      rescue ArgumentError
        next
      end
    end
end
