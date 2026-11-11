require "test_helper"

class BoardControllerTest < ActionDispatch::IntegrationTest
  test "shows only the signed-in user's tasks, grouped by status" do
    sign_in users(:one)
    get board_path

    assert_response :success
    assert_select "p", text: tasks(:read_chapter_three).title
    assert_select "p", text: tasks(:review_notes).title, count: 0
  end

  test "generates today's recurring tasks on load" do
    travel_to Date.new(2026, 11, 8).in_time_zone(users(:one).time_zone).noon do
      sign_in users(:one)

      assert_difference -> { users(:one).tasks.count }, 1 do
        get board_path
      end

      assert_select "p", text: recurring_tasks(:daily_standup).title
    end
  end

  test "requires sign-in" do
    get board_path
    assert_redirected_to new_session_path
  end
end
