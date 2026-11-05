require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @owner = { user: @user, device: devices(:one_phone) }
  end

  def in_kolkata(&block)
    Time.use_zone("Asia/Kolkata") { travel_to(Time.zone.local(2026, 11, 5, 20, 0), &block) }
  end

  def usage(package, seconds, date: Date.current)
    AppUsageDay.create!(**@owner, date: date, package_name: package, foreground_seconds: seconds, launches: 1)
  end

  test "only 7 and 30 day ranges are allowed" do
    assert_equal 7, Dashboard.new(@user, days: 0).days
    assert_equal 30, Dashboard.new(@user, days: 30).days
    assert_equal 7, Dashboard.new(@user, days: 999).dates.size
  end

  test "splits app time into Instagram, YouTube and other apps, without the launcher" do
    usage(Dashboard::INSTAGRAM, 3600)
    usage(Dashboard::YOUTUBE, 600)
    usage("com.whatsapp", 300)
    usage("com.google.android.apps.nexuslauncher", 5000)
    usage("com.android.systemui", 900)

    dashboard = Dashboard.new(@user)

    assert_equal({ instagram: 60, youtube: 10, other: 5 }, dashboard.app_minutes_by_day[Date.current])
    assert_equal 75, dashboard.screen_minutes(Date.current)
    assert_equal [ Dashboard::INSTAGRAM, Dashboard::YOUTUBE, "com.whatsapp" ], dashboard.top_apps.pluck(:package_name)
  end

  test "averages app time over earlier days that have data" do
    usage("com.whatsapp", 1200, date: Date.current - 1)
    usage("com.whatsapp", 2400, date: Date.current - 2)
    usage("com.whatsapp", 9999)

    assert_equal 30, Dashboard.new(@user).average_screen_minutes
  end

  test "splits app sessions across hours in the user's time zone" do
    in_kolkata do
      AppSession.create!(**@owner, package_name: Dashboard::INSTAGRAM,
                         started_at: Time.zone.local(2026, 11, 5, 9, 40), ended_at: Time.zone.local(2026, 11, 5, 10, 25))

      hours = Dashboard.new(@user).hourly_minutes[Date.current]

      assert_equal 20, hours[9]
      assert_equal 25, hours[10]
      assert_equal 45, hours.sum
    end
  end

  test "counts pickups and steps per local day" do
    in_kolkata do
      # 20:00 UTC on Nov 4 is 01:30 on Nov 5 in Kolkata.
      ScreenEvent.create!(**@owner, kind: "unlock", occurred_at: Time.utc(2026, 11, 4, 20, 0))
      ScreenEvent.create!(**@owner, kind: "unlock", occurred_at: Time.utc(2026, 11, 4, 10, 0))
      HealthSample.create!(**@owner, kind: "steps", recorded_at: Time.utc(2026, 11, 4, 20, 0), value: 1200, unit: "count", source_package: "x")
      HealthSample.create!(**@owner, kind: "steps", recorded_at: Time.utc(2026, 11, 5, 4, 0), value: 300, unit: "count", source_package: "x")

      dashboard = Dashboard.new(@user)

      assert_equal 1, dashboard.pickups_by_day[Date.new(2026, 11, 5)]
      assert_equal 1, dashboard.pickups_by_day[Date.new(2026, 11, 4)]
      assert_equal 1500, dashboard.steps_by_day[Date.new(2026, 11, 5)]
    end
  end

  test "heart rate per day and per 15 minutes" do
    in_kolkata do
      [ 58, 64, 90 ].each_with_index do |bpm, index|
        HealthSample.create!(**@owner, kind: "heart_rate", recorded_at: Time.zone.local(2026, 11, 5, 18, index * 5), value: bpm, unit: "bpm", source_package: "x")
      end

      dashboard = Dashboard.new(@user)

      assert_equal({ low: 58, average: 71 }, dashboard.heart_rate_by_day[Date.current])
      assert_equal [ [ Time.zone.local(2026, 11, 5, 18, 0), 71 ] ], dashboard.heart_rate_last_24_hours
    end
  end

  test "groups sleep stages by wake-up day and counts unstaged nights as asleep" do
    in_kolkata do
      start = Time.zone.local(2026, 11, 4, 23, 0)
      SleepSession.create!(**@owner, source_package: "x", started_at: start, ended_at: start + 7.hours, stages: [
        { "stage" => "deep", "start" => start.iso8601, "end" => (start + 2.hours).iso8601 },
        { "stage" => "light", "start" => (start + 2.hours).iso8601, "end" => (start + 6.hours).iso8601 },
        { "stage" => "awake", "start" => (start + 6.hours).iso8601, "end" => (start + 7.hours).iso8601 }
      ])
      SleepSession.create!(**@owner, source_package: "x", started_at: start - 1.day, ended_at: start - 1.day + 6.hours)

      nights = Dashboard.new(@user).sleep_by_night

      today = nights[Date.new(2026, 11, 5)]
      assert_equal 360, today[:asleep_minutes]
      assert_equal 60, today[:minutes]["awake"]
      assert_equal 360, nights[Date.new(2026, 11, 4)][:minutes]["asleep"]
    end
  end

  test "never includes another user's data" do
    AppUsageDay.create!(user: users(:two), device: devices(:two_phone), date: Date.current,
                        package_name: Dashboard::INSTAGRAM, foreground_seconds: 3600, launches: 1)

    assert_equal 0, Dashboard.new(@user).screen_minutes(Date.current)
  end
end
