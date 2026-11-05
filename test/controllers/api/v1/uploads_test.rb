require "test_helper"

# The five collector upload endpoints share BatchUpload; app_usage_days covers
# the shared behaviour, the others are checked for their own fields.
class Api::V1::UploadsTest < ActionDispatch::IntegrationTest
  def usage_item(**overrides)
    { date: Date.current.iso8601, package_name: "com.instagram.android", app_label: "Instagram",
      foreground_seconds: 3720, launches: 41, first_used_at: 3.hours.ago.utc.iso8601,
      last_used_at: 1.hour.ago.utc.iso8601 }.merge(overrides)
  end

  def heart_rate(value: 78, at: 1.hour.ago)
    { kind: "heart_rate", recorded_at: at.utc.iso8601, value: value, unit: "bpm",
      source_package: "com.nothing.smartcenter", external_id: "hc-1" }
  end

  test "upserts daily app usage" do
    api_post api_v1_app_usage_days_path, { items: [ usage_item, usage_item(package_name: "com.whatsapp", app_label: "WhatsApp") ] }

    assert_response :success
    assert_equal 2, response.parsed_body["upserted"]
    row = users(:one).app_usage_days.find_by!(package_name: "com.instagram.android")
    assert_equal [ devices(:one_phone), 3720, 41 ], [ row.device, row.foreground_seconds, row.launches ]
  end

  test "re-uploading updates rows instead of duplicating them" do
    api_post api_v1_app_usage_days_path, { items: [ usage_item ] }

    assert_no_difference -> { AppUsageDay.count } do
      api_post api_v1_app_usage_days_path, { items: [ usage_item(foreground_seconds: 4000) ] }
    end

    assert_response :success
    assert_equal 4000, AppUsageDay.sole.foreground_seconds
  end

  test "skips items older than the retention window" do
    api_post api_v1_app_usage_days_path, { items: [ usage_item, usage_item(date: (Date.current - DataRetention::DAYS).iso8601) ] }

    assert_response :success
    assert_equal({ "upserted" => 1, "skipped" => 1 }, response.parsed_body)
    assert_equal [ Date.current ], AppUsageDay.pluck(:date)
  end

  test "a batch of only stale items succeeds without saving anything" do
    api_post api_v1_screen_events_path, { items: [ { kind: "unlock", occurred_at: 30.days.ago.utc.iso8601 } ] }

    assert_response :success
    assert_equal({ "upserted" => 0, "skipped" => 1 }, response.parsed_body)
    assert_equal 0, ScreenEvent.count
  end

  test "keeps the last of duplicate items in one batch" do
    api_post api_v1_app_usage_days_path, { items: [ usage_item(foreground_seconds: 10), usage_item(foreground_seconds: 20) ] }

    assert_response :success
    assert_equal 1, response.parsed_body["upserted"]
    assert_equal 20, AppUsageDay.sole.foreground_seconds
  end

  test "an invalid item rejects the whole batch and lists its index" do
    assert_no_difference -> { AppUsageDay.count } do
      api_post api_v1_app_usage_days_path, { items: [ usage_item, usage_item(foreground_seconds: -5) ] }
    end

    assert_response :unprocessable_entity
    error = response.parsed_body["error"]
    assert_equal "validation_failed", error["code"]
    assert_equal [ 1 ], error["details"].pluck("index")
  end

  test "requires items" do
    api_post api_v1_app_usage_days_path, { items: [] }
    assert_response :unprocessable_entity

    api_post api_v1_app_usage_days_path, {}
    assert_response :unprocessable_entity
  end

  test "rejects more than the maximum number of items" do
    api_post api_v1_app_usage_days_path, { items: Array.new(BatchUpload::MAX_ITEMS + 1) { usage_item } }

    assert_response :unprocessable_entity
    assert_equal 0, AppUsageDay.count
  end

  test "rejects missing, invalid, revoked and expired tokens" do
    [ nil, "fo_wrong", "fo_test_revoked", "fo_test_expired" ].each do |token|
      api_post api_v1_app_usage_days_path, { items: [ usage_item ] }, token: token

      assert_response :unauthorized, "token #{token.inspect}"
      assert_equal "invalid_token", response.parsed_body.dig("error", "code")
    end
    assert_equal 0, AppUsageDay.count
  end

  test "rejects bodies over 1 MB" do
    body = { items: [ usage_item(app_label: "x" * (Api::V1::BaseController::MAX_BODY_BYTES + 1)) ] }.to_json
    post api_v1_app_usage_days_path, params: body,
         headers: auth_header("fo_test_one").merge("CONTENT_TYPE" => "application/json")

    assert_response 413
    assert_equal "payload_too_large", response.parsed_body.dig("error", "code")
  end

  test "rejects malformed JSON" do
    post api_v1_app_usage_days_path, params: "{not json",
         headers: auth_header("fo_test_one").merge("CONTENT_TYPE" => "application/json")

    assert_response :bad_request
    assert_equal "invalid_json", response.parsed_body.dig("error", "code")
  end

  test "rate limits each device across endpoints" do
    Api::V1::BaseController::REQUESTS_PER_HOUR.times { api_post api_v1_devices_heartbeat_path }
    assert_response :success

    api_post api_v1_app_usage_days_path, { items: [ usage_item ] }
    assert_response :too_many_requests

    api_post api_v1_app_usage_days_path, { items: [ usage_item ] }, token: "fo_test_two"
    assert_response :success
  end

  test "one user's uploads never touch another user's rows" do
    api_post api_v1_health_samples_path, { items: [ heart_rate(value: 70, at: 2.hours.ago.beginning_of_minute) ] }
    api_post api_v1_health_samples_path, { items: [ heart_rate(value: 120, at: 2.hours.ago.beginning_of_minute) ] },
             token: "fo_test_two"

    assert_response :success
    assert_equal [ 70 ], users(:one).health_samples.pluck(:value)
    assert_equal [ 120 ], users(:two).health_samples.pluck(:value)
  end

  test "stores app sessions with their duration" do
    api_post api_v1_app_sessions_path, { items: [ { package_name: "com.google.android.youtube",
                                                    started_at: 40.minutes.ago.utc.iso8601, ended_at: 10.minutes.ago.utc.iso8601 } ] }

    assert_response :success
    assert_equal 30 * 60, users(:one).app_sessions.sole.duration_seconds
  end

  test "stores screen events" do
    api_post api_v1_screen_events_path, { items: [ { kind: "unlock", occurred_at: 5.minutes.ago.utc.iso8601 },
                                                   { kind: "screen_on", occurred_at: 5.minutes.ago.utc.iso8601 } ] }

    assert_response :success
    assert_equal %w[screen_on unlock], users(:one).screen_events.pluck(:kind).sort
  end

  test "validates health sample ranges" do
    api_post api_v1_health_samples_path, { items: [ heart_rate, heart_rate(value: 400, at: 30.minutes.ago) ] }

    assert_response :unprocessable_entity
    assert_equal [ 1 ], response.parsed_body.dig("error", "details").pluck("index")
  end

  test "stores sleep sessions with stages" do
    night = { started_at: 9.hours.ago.utc.iso8601, ended_at: 1.hour.ago.utc.iso8601,
              source_package: "com.nothing.smartcenter", external_id: "hc-sleep-1",
              stages: [ { stage: "deep", start: 8.hours.ago.utc.iso8601, end: 7.hours.ago.utc.iso8601 } ] }

    api_post api_v1_sleep_sessions_path, { items: [ night ] }

    assert_response :success
    session = users(:one).sleep_sessions.sole
    assert_equal "deep", session.stages.first["stage"]
    assert_equal 480, session.duration_minutes
  end

  test "heartbeat stores permissions and the sync time" do
    api_post api_v1_devices_heartbeat_path, { app_version: "0.1.1",
                                              permissions: { usage_access: true, health_connect: %w[heart_rate sleep], battery_exempt: false },
                                              summary: { app_usage_days: 12 } }

    assert_response :success
    assert_equal Api::V1::DevicesController::MIN_APP_VERSION, response.parsed_body["min_app_version"]
    device = devices(:one_phone).reload
    assert_equal "0.1.1", device.app_version
    assert_equal %w[heart_rate sleep], device.permissions["health_connect"]
    assert_equal 12, device.last_sync_summary["app_usage_days"]
    assert_in_delta Time.current, device.last_sync_at, 5.seconds
  end
end
