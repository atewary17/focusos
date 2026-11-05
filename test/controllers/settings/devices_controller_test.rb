require "test_helper"

class Settings::DevicesControllerTest < ActionDispatch::IntegrationTest
  test "requires sign-in" do
    get settings_devices_path
    assert_redirected_to new_session_path
  end

  test "lists only the user's own devices" do
    sign_in users(:one)
    get settings_devices_path

    assert_response :success
    assert_select "p", text: devices(:one_phone).name
    assert_select "p", text: devices(:two_phone).name, count: 0
  end

  test "signing out a device deletes its tokens and keeps its data" do
    AppUsageDay.create!(user: users(:one), device: devices(:one_phone), date: Date.current,
                        package_name: "com.instagram.android", foreground_seconds: 60, launches: 1)
    sign_in users(:one)

    delete settings_device_path(devices(:one_phone))

    assert_redirected_to settings_devices_path
    assert_empty devices(:one_phone).api_tokens
    assert_equal 1, users(:one).app_usage_days.count
    assert_nil ApiToken.authenticate("fo_test_one")
  end

  test "cannot sign out another user's device" do
    sign_in users(:one)
    delete settings_device_path(devices(:two_phone))

    assert_response :not_found
    assert ApiToken.authenticate("fo_test_two")
  end
end
