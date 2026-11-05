require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "requires sign-in" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "shows charts and numbers from the user's data" do
    owner = { user: users(:one), device: devices(:one_phone) }
    AppUsageDay.create!(**owner, date: Date.current, package_name: Dashboard::INSTAGRAM, app_label: "Instagram",
                        foreground_seconds: 3720, launches: 20)
    HealthSample.create!(**owner, kind: "heart_rate", recorded_at: 2.hours.ago, value: 60, unit: "bpm", source_package: "x")
    HealthSample.create!(**owner, kind: "heart_rate", recorded_at: 1.hour.ago, value: 70, unit: "bpm", source_package: "x")
    SleepSession.create!(**owner, source_package: "x", started_at: 10.hours.ago, ended_at: 3.hours.ago)

    sign_in users(:one)
    get dashboard_path

    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select "p.text-5xl", "1h 02m"
    assert_select "h2", "App time per day"
    assert_select "h2", "Heart rate, last 24 hours"
    assert_select "[data-controller=chart]", minimum: 4
  end

  test "says how many days are kept" do
    sign_in users(:one)
    get dashboard_path

    assert_response :success
    assert_select "p", text: /Showing the last #{DataRetention::DAYS} days/
  end

  test "shows another user's numbers to nobody else" do
    AppUsageDay.create!(user: users(:two), device: devices(:two_phone), date: Date.current,
                        package_name: "com.secret.app", app_label: "SecretApp", foreground_seconds: 3000, launches: 1)

    sign_in users(:one)
    get dashboard_path

    assert_select "span", text: "SecretApp", count: 0
    assert_select "p.text-5xl", "0m"
  end

  test "explains what to do before a phone is connected" do
    users(:one).api_tokens.delete_all
    users(:one).devices.delete_all
    sign_in users(:one)
    get dashboard_path

    assert_select "p", text: "No phone connected yet."
  end
end
