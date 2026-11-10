require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "creates an unscheduled card by default" do
    assert_difference -> { users(:one).tasks.count } do
      post tasks_path, params: { task: { title: "Practice problems", topic_id: topics(:indifference_curves).id } }
    end
    assert_redirected_to plan_path
    task = users(:one).tasks.order(:created_at).last
    assert_nil task.scheduled_on
    assert_equal subjects(:economics), task.subject
  end

  test "schedules a card onto a day, with an optional time" do
    post tasks_path, params: { task: { title: "Read", scheduled_on: Date.current.iso8601, starts_time: "09:30" } }

    task = users(:one).tasks.order(:created_at).last
    assert_equal Date.current, task.scheduled_on
    assert_equal "09:30", task.starts_at.in_time_zone(users(:one).time_zone).strftime("%H:%M")
  end

  test "rejects a card without a title" do
    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: { title: "" } }
    end
  end

  test "updates and destroys the user's own card" do
    patch task_path(tasks(:read_chapter_three)), params: { task: { title: "Renamed" } }
    assert_equal "Renamed", tasks(:read_chapter_three).reload.title

    assert_difference -> { Task.count }, -1 do
      delete task_path(tasks(:read_chapter_three))
    end
  end

  test "cannot update or destroy another user's card" do
    patch task_path(tasks(:review_notes)), params: { task: { title: "x" } }
    assert_response :not_found

    delete task_path(tasks(:review_notes))
    assert_response :not_found
  end

  test "cannot attach a card to another user's topic" do
    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: { title: "Spy", topic_id: topics(:world_war_one).id } }
    end
  end

  test "toggle flips status between pending and done" do
    patch toggle_task_path(tasks(:read_chapter_three))
    assert_equal "done", tasks(:read_chapter_three).reload.status

    patch toggle_task_path(tasks(:read_chapter_three))
    assert_equal "pending", tasks(:read_chapter_three).reload.status
  end

  test "cannot toggle another user's card" do
    patch toggle_task_path(tasks(:review_notes))
    assert_response :not_found
  end

  test "reorder moves cards between days and sets their position" do
    other_task = users(:one).tasks.create!(title: "Second unscheduled card")
    today = Date.current.iso8601

    patch reorder_tasks_path, params: { days: { unscheduled: [], today => [ other_task.id, tasks(:read_chapter_three).id ] } },
          as: :json

    assert_response :no_content
    assert_equal Date.current, tasks(:read_chapter_three).reload.scheduled_on
    assert_equal 1, tasks(:read_chapter_three).reload.position
    assert_equal 0, other_task.reload.position
  end

  test "reorder never moves another user's cards" do
    patch reorder_tasks_path, params: { days: { Date.current.iso8601 => [ tasks(:review_notes).id ] } }, as: :json

    assert_response :no_content
    assert_nil tasks(:review_notes).reload.scheduled_on
  end

  test "reorder rejects a day key that isn't a date" do
    patch reorder_tasks_path, params: { days: { "not-a-date" => [ tasks(:read_chapter_three).id ] } }, as: :json

    assert_response :unprocessable_entity
    assert_nil tasks(:read_chapter_three).reload.scheduled_on
  end
end
