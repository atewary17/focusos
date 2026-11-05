require "test_helper"

class Api::V1::TokensControllerTest < ActionDispatch::IntegrationTest
  DEVICE = { installation_id: "33333333-3333-4333-8333-333333333333", kind: "android", name: "Pixel 7",
             manufacturer: "Google", model: "Pixel 7", os_version: "15", app_version: "0.1.0" }.freeze

  def sign_in_api(password: "password", device: DEVICE, email: users(:one).email_address)
    api_post api_v1_tokens_path, { email_address: email, password: password, device: device }, token: nil
  end

  test "signs in, registers the device and returns a working token" do
    assert_difference -> { users(:one).devices.count } => 1, -> { ApiToken.count } => 1 do
      sign_in_api
    end

    assert_response :created
    body = response.parsed_body
    assert body["token"].start_with?(ApiToken::PREFIX)
    assert_equal "Asia/Kolkata", body.dig("user", "time_zone")

    device = Device.find(body["device_id"])
    assert_equal [ users(:one), "Pixel 7", "15" ], [ device.user, device.model, device.os_version ]

    api_post api_v1_devices_heartbeat_path, {}, token: body["token"]
    assert_response :success
  end

  test "signing in again from the same phone reuses the device and replaces its token" do
    sign_in_api
    first = response.parsed_body

    assert_no_difference -> { Device.count } do
      sign_in_api(device: DEVICE.merge(app_version: "0.2.0"))
    end
    second = response.parsed_body

    assert_equal first["device_id"], second["device_id"]
    assert_equal "0.2.0", Device.find(second["device_id"]).app_version
    assert_nil ApiToken.authenticate(first["token"])
    assert ApiToken.authenticate(second["token"])
  end

  test "rejects a wrong password" do
    assert_no_difference -> { ApiToken.count } do
      sign_in_api(password: "wrong-password")
    end

    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
  end

  test "requires device details" do
    sign_in_api(device: nil)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body.dig("error", "code")
  end

  test "limits sign-in attempts" do
    10.times { sign_in_api(password: "wrong-password") }
    sign_in_api

    assert_response :too_many_requests
    assert_equal "rate_limited", response.parsed_body.dig("error", "code")
  end

  test "sign out revokes the token" do
    delete api_v1_tokens_current_path, headers: auth_header("fo_test_one")
    assert_response :no_content

    api_post api_v1_devices_heartbeat_path
    assert_response :unauthorized
  end
end
