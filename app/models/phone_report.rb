# Read-only numbers for the /phone page: minutes per app per day and pickups,
# for the last DAYS days in the user's time zone. Time is per app (Instagram
# includes DMs, YouTube includes lectures).
class PhoneReport
  TRACKED_APPS = { "com.instagram.android" => "Instagram", "com.google.android.youtube" => "YouTube" }.freeze
  TOP_APPS = 10
  DAYS = 7

  attr_reader :dates

  def initialize(user, today: Date.current)
    @user = user
    @dates = (0...DAYS).map { |offset| today - offset }
  end

  # Instagram and YouTube first, then the other top apps by total time.
  # Each row: { package_name:, label:, minutes: { date => minutes } }
  def rows
    (TRACKED_APPS.keys + top_other_apps).map do |package|
      { package_name: package, label: label_for(package),
        minutes: dates.index_with { |date| (seconds[[ package, date ]].to_i / 60.0).round } }
    end
  end

  # Unlocks per day.
  def pickups
    counts = @user.screen_events.where(kind: "unlock", occurred_at: dates.last.beginning_of_day..dates.first.end_of_day)
                  .pluck(:occurred_at).map { |time| time.in_time_zone.to_date }.tally
    dates.index_with { |date| counts[date].to_i }
  end

  def devices
    @user.devices.order(Arel.sql("last_sync_at DESC NULLS LAST"))
  end

  def any_data?
    seconds.any?
  end

  private
    def seconds
      @seconds ||= @user.app_usage_days.where(date: dates).group(:package_name, :date).sum(:foreground_seconds)
    end

    def top_other_apps
      totals = Hash.new(0)
      seconds.each { |(package, _date), value| totals[package] += value unless TRACKED_APPS.key?(package) }
      totals.sort_by { |_package, total| -total }.first(TOP_APPS).map(&:first)
    end

    def label_for(package)
      labels[package].presence || TRACKED_APPS[package] || package
    end

    def labels
      @labels ||= @user.app_usage_days.where(date: dates).where.not(app_label: nil).pluck(:package_name, :app_label).to_h
    end
end
