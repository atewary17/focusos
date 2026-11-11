require "test_helper"

class RecurringTasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "creates a recurring task for the signed-in user" do
    assert_difference -> { users(:one).recurring_tasks.count } do
      post recurring_tasks_path, params: { recurring_task: { title: "Gym", days_of_week: %w[1 3 5] } }
    end
    assert_redirected_to board_path
    assert_equal [ 1, 3, 5 ], users(:one).recurring_tasks.find_by!(title: "Gym").days_of_week
  end

  test "rejects a recurring task with no days" do
    assert_no_difference -> { RecurringTask.count } do
      post recurring_tasks_path, params: { recurring_task: { title: "Gym", days_of_week: [] } }
    end
  end

  test "updates the user's own recurring task" do
    patch recurring_task_path(recurring_tasks(:daily_standup)), params: { recurring_task: { title: "Renamed" } }
    assert_equal "Renamed", recurring_tasks(:daily_standup).reload.title
  end

  test "toggle flips active" do
    patch toggle_recurring_task_path(recurring_tasks(:daily_standup))
    assert_not recurring_tasks(:daily_standup).reload.active?

    patch toggle_recurring_task_path(recurring_tasks(:daily_standup))
    assert recurring_tasks(:daily_standup).reload.active?
  end

  test "destroys the user's own recurring task" do
    assert_difference -> { RecurringTask.count }, -1 do
      delete recurring_task_path(recurring_tasks(:daily_standup))
    end
  end

  test "cannot update, toggle or destroy another user's recurring task" do
    patch recurring_task_path(recurring_tasks(:weekend_only)), params: { recurring_task: { title: "x" } }
    assert_response :not_found

    patch toggle_recurring_task_path(recurring_tasks(:weekend_only))
    assert_response :not_found

    delete recurring_task_path(recurring_tasks(:weekend_only))
    assert_response :not_found
  end
end
