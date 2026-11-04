require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def signup_params(overrides = {})
    {
      user: {
        name: "Kabir Das",
        email_address: "kabir@example.com",
        password: "focus-first",
        password_confirmation: "focus-first",
        time_zone: "Asia/Kolkata",
        terms_accepted: "1"
      }.merge(overrides)
    }
  end

  teardown { ENV.delete("SIGNUP_INVITE_CODE") }

  test "shows the sign-up form" do
    get new_registration_path
    assert_response :success
    assert_select "h1", "Create your account"
  end

  test "creates an account and signs the user in" do
    assert_difference("User.count", 1) do
      post registration_path, params: signup_params
    end
    assert_redirected_to root_path
    assert cookies[:session_id].present?

    follow_redirect!
    assert_response :success
    assert_select "h1", /Kabir/
  end

  test "rejects sign-up without consent" do
    assert_no_difference("User.count") do
      post registration_path, params: signup_params(terms_accepted: "0")
    end
    assert_response 422
  end

  test "rejects mismatched passwords" do
    assert_no_difference("User.count") do
      post registration_path, params: signup_params(password_confirmation: "something-else")
    end
    assert_response 422
  end

  test "requires the invite code when one is configured" do
    ENV["SIGNUP_INVITE_CODE"] = "study-buddies"

    assert_no_difference("User.count") do
      post registration_path, params: signup_params.merge(invite_code: "wrong")
    end
    assert_response 422
    assert_select "li", "Invite code is not valid"

    assert_difference("User.count", 1) do
      post registration_path, params: signup_params.merge(invite_code: "study-buddies")
    end
    assert_redirected_to root_path
  end

  test "signed-in users are sent to Today" do
    sign_in users(:one)
    get new_registration_path
    assert_redirected_to root_path
  end
end
