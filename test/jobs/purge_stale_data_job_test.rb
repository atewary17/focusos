require "test_helper"

class PurgeStaleDataJobTest < ActiveJob::TestCase
  test "deletes stale data for every user and keeps recent data" do
    [ [ users(:one), devices(:one_phone) ], [ users(:two), devices(:two_phone) ] ].each do |user, device|
      ScreenEvent.create!(user: user, device: device, kind: "unlock", occurred_at: 20.days.ago)
      ScreenEvent.create!(user: user, device: device, kind: "unlock", occurred_at: 1.hour.ago)
    end

    PurgeStaleDataJob.perform_now

    assert_equal 1, users(:one).screen_events.count
    assert_equal 1, users(:two).screen_events.count
  end

  test "is scheduled hourly in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "purge_stale_data")
    assert_equal "PurgeStaleDataJob", schedule["class"]
    assert_match(/every hour/, schedule["schedule"])
  end
end
