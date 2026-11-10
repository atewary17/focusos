require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "shows scheduled tasks on their day and unscheduled tasks in the sidebar" do
    sign_in users(:one)
    tasks(:read_chapter_three).reschedule!(Date.current, Time.zone.parse("09:00"))
    other = users(:one).tasks.create!(title: "No time yet")

    get calendar_path

    assert_response :success
    assert_select "[data-task-id='#{tasks(:read_chapter_three).id}']"
    assert_select "[data-task-id='#{other.id}']"
  end

  test "does not show another user's tasks" do
    sign_in users(:one)
    get calendar_path
    assert_response :success
    assert_select "[data-task-id='#{tasks(:review_notes).id}']", count: 0
  end

  test "start param snaps to the Monday of that week" do
    sign_in users(:one)
    get calendar_path, params: { start: "2026-11-12" } # a Thursday

    assert_response :success
    assert_select "p", text: /9 Nov/ # the week's Monday
  end

  test "requires sign-in" do
    get calendar_path
    assert_redirected_to new_session_path
  end
end
