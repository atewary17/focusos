require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "creates a card in the given lane" do
    assert_difference -> { users(:one).tasks.count } do
      post tasks_path, params: { task: { title: "Practice problems", lane: "next", topic_id: topics(:indifference_curves).id } }
    end
    assert_redirected_to board_path
    assert_equal subjects(:economics), users(:one).tasks.order(:created_at).last.subject
  end

  test "rejects a card without a title" do
    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: { title: "", lane: "backlog" } }
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
      post tasks_path, params: { task: { title: "Spy", lane: "backlog", topic_id: topics(:world_war_one).id } }
    end
  end

  test "reorder moves cards between lanes and sets their position" do
    other_task = users(:one).tasks.create!(title: "Second backlog card", lane: "backlog")

    patch reorder_tasks_path, params: { lanes: { backlog: [], today: [ other_task.id, tasks(:read_chapter_three).id ] } },
          as: :json

    assert_response :no_content
    assert_equal "today", tasks(:read_chapter_three).reload.lane
    assert_equal 1, tasks(:read_chapter_three).reload.position
    assert_equal 0, other_task.reload.position
  end

  test "reorder never moves another user's cards" do
    patch reorder_tasks_path, params: { lanes: { done: [ tasks(:review_notes).id ] } }, as: :json

    assert_response :no_content
    assert_equal "backlog", tasks(:review_notes).reload.lane
  end
end
