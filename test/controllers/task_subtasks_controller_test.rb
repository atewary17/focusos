require "test_helper"

class TaskSubtasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "adds a subtask" do
    post task_subtasks_path(tasks(:read_chapter_three)), params: { text: "Read page one" }
    assert_equal [ "Read page one" ], tasks(:read_chapter_three).reload.subtasks.pluck("text")
  end

  test "ignores a blank subtask" do
    assert_no_changes -> { tasks(:read_chapter_three).reload.subtasks } do
      post task_subtasks_path(tasks(:read_chapter_three)), params: { text: "" }
    end
  end

  test "toggles and removes a subtask by index" do
    tasks(:read_chapter_three).add_subtask!("Read page one")

    patch task_toggle_task_subtask_path(tasks(:read_chapter_three), subtask_id: 0)
    assert tasks(:read_chapter_three).reload.subtasks[0]["done"]

    delete task_task_subtask_path(tasks(:read_chapter_three), subtask_id: 0)
    assert_empty tasks(:read_chapter_three).reload.subtasks
  end

  test "cannot add, toggle or remove a subtask on another user's card" do
    post task_subtasks_path(tasks(:review_notes)), params: { text: "x" }
    assert_response :not_found

    patch task_toggle_task_subtask_path(tasks(:review_notes), subtask_id: 0)
    assert_response :not_found

    delete task_task_subtask_path(tasks(:review_notes), subtask_id: 0)
    assert_response :not_found
  end
end
