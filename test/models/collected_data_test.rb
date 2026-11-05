require "test_helper"

# Validations for the rows the Android collector uploads.
class CollectedDataTest < ActiveSupport::TestCase
  setup { @owner = { user: users(:one), device: devices(:one_phone) } }

  def build(model, **attributes)
    model.new(**@owner, **attributes)
  end

  test "health sample ranges depend on kind" do
    assert build(HealthSample, kind: "heart_rate", value: 72, unit: "bpm", recorded_at: 1.hour.ago, source_package: "x").valid?
    assert build(HealthSample, kind: "heart_rate", value: 300, unit: "bpm", recorded_at: 1.hour.ago, source_package: "x").invalid?
    assert build(HealthSample, kind: "spo2", value: 101, unit: "%", recorded_at: 1.hour.ago, source_package: "x").invalid?
    assert build(HealthSample, kind: "stress", value: 5, unit: "x", recorded_at: 1.hour.ago, source_package: "x").invalid?
  end

  test "timestamps may not be in the future beyond a small tolerance" do
    assert build(ScreenEvent, kind: "unlock", occurred_at: 2.minutes.from_now).valid?
    assert build(ScreenEvent, kind: "unlock", occurred_at: 1.hour.from_now).invalid?
  end

  test "app session computes its duration and rejects an end before the start" do
    session = build(AppSession, package_name: "com.instagram.android", started_at: 30.minutes.ago, ended_at: 10.minutes.ago)
    assert session.valid?
    assert_equal 20 * 60, session.duration_seconds

    assert build(AppSession, package_name: "x", started_at: 10.minutes.ago, ended_at: 30.minutes.ago).invalid?
  end

  test "app usage day rejects negative time and far-future dates" do
    assert build(AppUsageDay, date: Date.current, package_name: "x", foreground_seconds: 60, launches: 1).valid?
    assert build(AppUsageDay, date: Date.current, package_name: "x", foreground_seconds: -1, launches: 1).invalid?
    assert build(AppUsageDay, date: Date.current + 3, package_name: "x", foreground_seconds: 60, launches: 1).invalid?
  end

  test "screen event kind must be known" do
    assert build(ScreenEvent, kind: "shake", occurred_at: 1.hour.ago).invalid?
  end

  test "sleep session stages must be well formed" do
    night = { started_at: 9.hours.ago, ended_at: 1.hour.ago, source_package: "com.nothing.smartcenter" }
    stage = { "stage" => "deep", "start" => 8.hours.ago.iso8601, "end" => 7.hours.ago.iso8601 }

    assert build(SleepSession, **night, stages: [ stage ]).valid?
    assert build(SleepSession, **night, stages: []).valid?
    assert build(SleepSession, **night, stages: [ stage.merge("stage" => "dreaming") ]).invalid?
    assert build(SleepSession, **night, stages: [ { "stage" => "deep" } ]).invalid?
  end
end
