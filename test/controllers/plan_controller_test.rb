require "test_helper"

class PlanControllerTest < ActionDispatch::IntegrationTest
  test "shows only the signed-in user's tasks, grouped by day" do
    tasks(:read_chapter_three).update!(scheduled_on: Date.current)

    sign_in users(:one)
    get plan_path

    assert_response :success
    assert_select "p", text: tasks(:read_chapter_three).title
    assert_select "p", text: tasks(:review_notes).title, count: 0
  end

  test "requires sign-in" do
    get plan_path
    assert_redirected_to new_session_path
  end
end
