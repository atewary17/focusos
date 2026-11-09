require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert tasks(:read_chapter_three).valid?
    assert tasks(:review_notes).valid?
  end

  test "assigns the next position within the lane" do
    task = users(:one).tasks.create!(title: "Practice problems", lane: "backlog")
    assert_equal tasks(:read_chapter_three).position + 1, task.position
  end

  test "a new lane starts at position 0" do
    task = users(:one).tasks.create!(title: "Draft essay", lane: "today")
    assert_equal 0, task.position
  end

  test "inherits the subject from its topic when none is given" do
    task = users(:one).tasks.create!(title: "Practice problems", topic: topics(:indifference_curves))
    assert_equal subjects(:economics), task.subject
  end

  test "moving a card into done completes it, moving it out reopens it" do
    task = tasks(:read_chapter_three)
    task.update!(lane: "done")
    assert_equal "done", task.status
    assert_not_nil task.completed_at

    task.update!(lane: "backlog")
    assert_equal "pending", task.status
    assert_nil task.completed_at
  end

  test "rejects a topic that belongs to another user" do
    task = Task.new(user: users(:one), title: "Spy on history", topic: topics(:world_war_one))
    assert_not task.valid?
    assert_includes task.errors[:topic], "must belong to you"
  end

  test "rejects a subject that belongs to another user" do
    task = Task.new(user: users(:one), title: "Spy on history", subject: subjects(:history))
    assert_not task.valid?
    assert_includes task.errors[:subject], "must belong to you"
  end

  test "rejects an out-of-range priority" do
    task = Task.new(user: users(:one), title: "x", priority: 4)
    assert_not task.valid?
  end

  test "reorder_board! moves cards across lanes and sets their position, scoped to the user" do
    other = users(:two).tasks.create!(title: "Not mine", lane: "backlog")
    mine = users(:one).tasks.create!(title: "Mine too", lane: "backlog")

    Task.reorder_board!(users(:one), {
      "backlog" => [],
      "today" => [ mine.id.to_s, tasks(:read_chapter_three).id.to_s ],
      "next" => [], "done" => []
    })

    assert_equal [ "today", "today" ], [ mine, tasks(:read_chapter_three) ].map { |t| t.reload.lane }
    assert_equal [ 0, 1 ], [ mine, tasks(:read_chapter_three) ].map { |t| t.reload.position }
    assert_equal "backlog", other.reload.lane, "another user's task must not move"
  end
end
