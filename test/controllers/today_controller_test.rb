require "test_helper"

class TodayControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign-in when signed out" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "greets the signed-in user" do
    sign_in users(:one)
    get root_path
    assert_response :success
    assert_select "h1", /Asha/
  end

  test "shows the date in the user's own time zone" do
    user = users(:two) # Europe/London
    travel_to Time.utc(2026, 11, 4, 23, 30) do # 05:00 next day in Kolkata, still the 4th in London
      sign_in user
      get root_path
    end
    assert_select "p", /Wednesday, 4 November/
  end
end
