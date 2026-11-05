require "test_helper"

class PhoneControllerTest < ActionDispatch::IntegrationTest
  test "requires sign-in" do
    get phone_path
    assert_redirected_to new_session_path
  end

  test "shows the user's devices and app minutes, not other users' data" do
    AppUsageDay.create!(user: users(:one), device: devices(:one_phone), date: Date.current,
                        package_name: "com.instagram.android", app_label: "Instagram", foreground_seconds: 1500, launches: 9)
    AppUsageDay.create!(user: users(:two), device: devices(:two_phone), date: Date.current,
                        package_name: "com.secret.app", app_label: "SecretApp", foreground_seconds: 900, launches: 2)

    sign_in users(:one)
    get phone_path

    assert_response :success
    assert_select "p", text: devices(:one_phone).name
    assert_select "td", text: "Instagram"
    assert_select "td", text: "25"
    assert_select "td", text: "SecretApp", count: 0
  end

  test "explains what to do before a phone is connected" do
    users(:one).devices.each { |device| device.api_tokens.destroy_all }
    users(:one).devices.delete_all
    sign_in users(:one)
    get phone_path

    assert_select "p", text: "No phone connected yet."
  end
end
