require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "creates an unscheduled, pending card by default, returning to the board" do
    assert_difference -> { users(:one).tasks.count } do
      post tasks_path, params: { task: { title: "Practice problems", topic_id: topics(:indifference_curves).id } }
    end
    assert_redirected_to board_path
    task = users(:one).tasks.order(:created_at).last
    assert_nil task.scheduled_on
    assert_equal "pending", task.status
    assert_equal subjects(:economics), task.subject
  end

  test "create returns to the calendar when return_to=calendar" do
    post tasks_path, params: { task: { title: "Read" }, return_to: "calendar" }
    assert_redirected_to calendar_path
  end

  test "creates a card directly into a status lane" do
    post tasks_path, params: { task: { title: "In progress", status: "doing" } }
    assert_equal "doing", users(:one).tasks.order(:created_at).last.status
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

  test "updates the user's own card" do
    patch task_path(tasks(:read_chapter_three)), params: { task: { title: "Renamed" } }
    assert_equal "Renamed", tasks(:read_chapter_three).reload.title
  end

  test "destroy soft-deletes the card and offers an undo link, without reducing the row count" do
    assert_no_difference -> { Task.count } do
      delete task_path(tasks(:read_chapter_three))
    end

    assert_redirected_to board_path
    assert_not_nil tasks(:read_chapter_three).reload.deleted_at
    assert_not_includes users(:one).tasks.kept, tasks(:read_chapter_three)
    assert_equal restore_task_path(tasks(:read_chapter_three)), flash[:undo_url]
  end

  test "restore brings a soft-deleted card back" do
    tasks(:read_chapter_three).soft_delete!

    patch restore_task_path(tasks(:read_chapter_three))

    assert_redirected_to board_path
    assert_nil tasks(:read_chapter_three).reload.deleted_at
  end

  test "cannot update, destroy or restore another user's card" do
    patch task_path(tasks(:review_notes)), params: { task: { title: "x" } }
    assert_response :not_found

    delete task_path(tasks(:review_notes))
    assert_response :not_found

    patch restore_task_path(tasks(:review_notes))
    assert_response :not_found
  end

  test "destroy_all hard-deletes every one of the user's cards, scheduled or not" do
    users(:one).tasks.create!(title: "Second unscheduled card")
    users(:one).tasks.create!(title: "Scheduled card", scheduled_on: Date.current)
    mine_before = users(:one).tasks.count

    assert_difference -> { Task.count }, -mine_before do
      delete destroy_all_tasks_path
    end

    assert_redirected_to board_path
    assert_equal 0, users(:one).tasks.count
  end

  test "destroy_all never touches another user's cards" do
    delete destroy_all_tasks_path
    assert tasks(:review_notes).reload.present?
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

  test "reschedule sets the day and time" do
    patch reschedule_task_path(tasks(:read_chapter_three)), params: { scheduled_on: Date.current.iso8601, starts_time: "14:30" },
          as: :json

    assert_response :no_content
    task = tasks(:read_chapter_three).reload
    assert_equal Date.current, task.scheduled_on
    assert_equal "14:30", task.starts_at.in_time_zone(users(:one).time_zone).strftime("%H:%M")
  end

  test "reschedule with blank params clears scheduling" do
    tasks(:read_chapter_three).reschedule!(Date.current, Time.zone.parse("09:00"))

    patch reschedule_task_path(tasks(:read_chapter_three)), params: { scheduled_on: "", starts_time: "" }, as: :json

    assert_response :no_content
    task = tasks(:read_chapter_three).reload
    assert_nil task.scheduled_on
    assert_nil task.starts_at
  end

  test "cannot reschedule another user's card" do
    patch reschedule_task_path(tasks(:review_notes)), params: { scheduled_on: Date.current.iso8601, starts_time: "09:00" },
          as: :json
    assert_response :not_found
  end

  test "reorder sets the calendar position of the unscheduled sidebar list" do
    other = users(:one).tasks.create!(title: "Second unscheduled card")

    patch reorder_tasks_path, params: { ids: [ other.id, tasks(:read_chapter_three).id ] }, as: :json

    assert_response :no_content
    assert_equal 0, other.reload.calendar_position
    assert_equal 1, tasks(:read_chapter_three).reload.calendar_position
  end

  test "reorder never moves another user's cards" do
    patch reorder_tasks_path, params: { ids: [ tasks(:review_notes).id ] }, as: :json
    assert_response :no_content
    assert_equal 0, tasks(:review_notes).reload.calendar_position
  end

  test "reorder_status moves cards between lanes and sets their board position" do
    other_task = users(:one).tasks.create!(title: "Second pending card")

    patch reorder_status_tasks_path, params: { statuses: { pending: [], doing: [ other_task.id, tasks(:read_chapter_three).id ] } },
          as: :json

    assert_response :no_content
    assert_equal "doing", tasks(:read_chapter_three).reload.status
    assert_equal 1, tasks(:read_chapter_three).reload.board_position
    assert_equal 0, other_task.reload.board_position
  end

  test "reorder_status never moves another user's cards" do
    patch reorder_status_tasks_path, params: { statuses: { done: [ tasks(:review_notes).id ] } }, as: :json

    assert_response :no_content
    assert_equal "pending", tasks(:review_notes).reload.status
  end

  test "reorder_status rejects a status key that isn't a real lane" do
    patch reorder_status_tasks_path, params: { statuses: { "archived" => [ tasks(:read_chapter_three).id ] } }, as: :json

    assert_response :unprocessable_entity
    assert_equal "pending", tasks(:read_chapter_three).reload.status
  end
end
