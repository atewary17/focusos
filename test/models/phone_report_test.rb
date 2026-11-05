require "test_helper"

class PhoneReportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @device = devices(:one_phone)
  end

  def usage(package, seconds, date: Date.current, label: nil)
    AppUsageDay.create!(user: @user, device: @device, date: date, package_name: package, app_label: label,
                        foreground_seconds: seconds, launches: 1)
  end

  test "lists Instagram and YouTube first, then other apps by total time" do
    usage("com.whatsapp", 600, label: "WhatsApp")
    usage("com.spotify.music", 1200, label: "Spotify")
    usage("com.instagram.android", 3690, label: "Instagram")

    rows = PhoneReport.new(@user).rows

    assert_equal %w[Instagram YouTube Spotify WhatsApp], rows.map { |row| row[:label] }
    assert_equal 62, rows.first[:minutes][Date.current]
    assert_equal 0, rows.second[:minutes][Date.current]
  end

  test "sums minutes per day and ignores other users' data" do
    usage("com.instagram.android", 600, date: Date.current - 1)
    AppUsageDay.create!(user: users(:two), device: devices(:two_phone), date: Date.current,
                        package_name: "com.instagram.android", foreground_seconds: 9999, launches: 1)

    minutes = PhoneReport.new(@user).rows.first[:minutes]

    assert_equal 10, minutes[Date.current - 1]
    assert_equal 0, minutes[Date.current]
  end

  test "counts unlocks per day in the user's time zone" do
    Time.use_zone("Asia/Kolkata") do
      travel_to Time.zone.local(2026, 11, 5, 12, 0) do
        # 19:00 UTC on Nov 4 is 00:30 on Nov 5 in Kolkata.
        ScreenEvent.create!(user: @user, device: @device, kind: "unlock", occurred_at: Time.utc(2026, 11, 4, 19, 0))
        ScreenEvent.create!(user: @user, device: @device, kind: "unlock", occurred_at: Time.utc(2026, 11, 4, 10, 0))
        ScreenEvent.create!(user: @user, device: @device, kind: "screen_on", occurred_at: Time.utc(2026, 11, 4, 10, 0))

        pickups = PhoneReport.new(@user).pickups

        assert_equal 1, pickups[Date.new(2026, 11, 5)]
        assert_equal 1, pickups[Date.new(2026, 11, 4)]
      end
    end
  end
end
