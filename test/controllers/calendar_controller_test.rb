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

  test "lays overlapping events out side by side instead of hiding one behind the other" do
    sign_in users(:one)
    tasks(:read_chapter_three).reschedule!(Date.current, Time.zone.parse("09:00"))
    overlapping = users(:one).tasks.create!(title: "Also at 9", estimate_minutes: 30)
    overlapping.reschedule!(Date.current, Time.zone.parse("09:15"))
    later = users(:one).tasks.create!(title: "After both", estimate_minutes: 30)
    later.reschedule!(Date.current, Time.zone.parse("11:00"))

    get calendar_path

    columns = @controller.instance_variable_get(:@columns_by_task_id)
    assert_equal [ 0, 2 ], columns[tasks(:read_chapter_three).id]
    assert_equal [ 1, 2 ], columns[overlapping.id]
    # Simplified layout: column count is per day, not per cluster, so a
    # later non-overlapping event still gets the day's column count (2),
    # just reusing an already-freed column (0) rather than a full-width one.
    assert_equal [ 0, 2 ], columns[later.id]
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
