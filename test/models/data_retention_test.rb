require "test_helper"

class DataRetentionTest < ActiveSupport::TestCase
  setup { @owner = { user: users(:one), device: devices(:one_phone) } }

  # Creates one row of every collected kind at `time` (its local date for daily totals).
  def collect_at(time, owner: @owner)
    AppUsageDay.create!(**owner, date: time.to_date, package_name: "com.instagram.android", foreground_seconds: 60, launches: 1)
    AppSession.create!(**owner, package_name: "com.instagram.android", started_at: time - 10.minutes, ended_at: time)
    ScreenEvent.create!(**owner, kind: "unlock", occurred_at: time)
    HealthSample.create!(**owner, kind: "heart_rate", recorded_at: time, value: 70, unit: "bpm", source_package: "x")
    SleepSession.create!(**owner, source_package: "x", started_at: time - 7.hours, ended_at: time)
    CheckIn.create!(**owner, asked_at: time, answer: "focused", answered_at: time)
  end

  def counts(user = users(:one))
    DataRetention::COLUMNS.keys.to_h { |model| [ model, model.constantize.where(user: user).count ] }
  end

  test "keeps today and the previous six local days, deletes everything older" do
    Time.use_zone("Asia/Kolkata") do
      travel_to Time.zone.local(2026, 11, 12, 2, 0) do
        collect_at(Time.zone.local(2026, 11, 6, 0, 30))   # oldest kept day
        collect_at(Time.zone.local(2026, 11, 5, 23, 30))  # one day too old

        deleted = DataRetention.purge!(users(:one))

        assert_equal DataRetention::COLUMNS.keys.index_with(1), deleted
        assert_equal DataRetention::COLUMNS.keys.index_with(1), counts
      end
    end
  end

  test "uses each user's own time zone" do
    users(:two).update!(time_zone: "Europe/London")
    two = { user: users(:two), device: devices(:two_phone) }

    travel_to Time.utc(2026, 11, 12, 1, 0) do
      # Nov 5, 21:00 UTC is Nov 6 in Kolkata (kept) but Nov 5 in London (deleted).
      evening = Time.utc(2026, 11, 5, 21, 0)
      Time.use_zone("Asia/Kolkata") { collect_at(evening.in_time_zone) }
      Time.use_zone("Europe/London") { collect_at(evening.in_time_zone, owner: two) }

      DataRetention.purge!(users(:one))
      DataRetention.purge!(users(:two))

      assert_equal 1, users(:one).screen_events.count
      assert_equal 0, users(:two).screen_events.count
    end
  end

  test "stale? compares dates and times against the cutoff" do
    Time.use_zone("Asia/Kolkata") do
      travel_to Time.zone.local(2026, 11, 12, 12, 0) do
        assert DataRetention.stale?(ScreenEvent.new(occurred_at: Time.zone.local(2026, 11, 5, 23, 59)))
        assert_not DataRetention.stale?(ScreenEvent.new(occurred_at: Time.zone.local(2026, 11, 6, 0, 0)))
        assert DataRetention.stale?(AppUsageDay.new(date: Date.new(2026, 11, 5)))
        assert_not DataRetention.stale?(AppUsageDay.new(date: Date.new(2026, 11, 6)))
        assert_not DataRetention.stale?(ScreenEvent.new(occurred_at: nil))
      end
    end
  end
end
