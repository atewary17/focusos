require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert tasks(:read_chapter_three).valid?
    assert tasks(:review_notes).valid?
  end

  test "assigns the next calendar position within the same day (nil groups as unscheduled)" do
    task = users(:one).tasks.create!(title: "Practice problems")
    assert_equal tasks(:read_chapter_three).calendar_position + 1, task.calendar_position
  end

  test "a new day starts calendar position at 0" do
    task = users(:one).tasks.create!(title: "Draft essay", scheduled_on: Date.current)
    assert_equal 0, task.calendar_position
  end

  test "assigns the next board position within the same status" do
    task = users(:one).tasks.create!(title: "Practice problems")
    assert_equal tasks(:read_chapter_three).board_position + 1, task.board_position
  end

  test "inherits the subject from its topic when none is given" do
    task = users(:one).tasks.create!(title: "Practice problems", topic: topics(:indifference_curves))
    assert_equal subjects(:economics), task.subject
  end

  test "clears starts_at when scheduled_on is cleared" do
    task = users(:one).tasks.create!(title: "Read", scheduled_on: Date.current, starts_at: Time.current)
    task.update!(scheduled_on: nil)
    assert_nil task.starts_at
  end

  test "toggle_done! marks a task done and back to pending" do
    task = tasks(:read_chapter_three)
    task.toggle_done!
    assert_equal "done", task.status
    assert_not_nil task.completed_at

    task.toggle_done!
    assert_equal "pending", task.status
    assert_nil task.completed_at
  end

  test "reschedule! sets the day, time and calendar position" do
    task = tasks(:read_chapter_three)
    other = users(:one).tasks.create!(title: "Already there", scheduled_on: Date.current)

    task.reschedule!(Date.current, Time.zone.parse("09:30"))

    assert_equal Date.current, task.scheduled_on
    assert_equal [ 9, 30 ], [ task.starts_at.hour, task.starts_at.min ]
    assert_equal other.calendar_position + 1, task.calendar_position
  end

  test "reschedule! with a nil date clears scheduling" do
    task = tasks(:read_chapter_three)
    task.reschedule!(Date.current, Time.zone.parse("09:30"))

    task.reschedule!(nil)

    assert_nil task.scheduled_on
    assert_nil task.starts_at
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

  test "accepts the doing status" do
    task = Task.new(user: users(:one), title: "x", status: "doing")
    assert task.valid?
  end

  test "subtask checklist: add, toggle and remove" do
    task = tasks(:read_chapter_three)
    task.add_subtask!("Mockups")
    task.add_subtask!("Data model")
    assert_equal [ "Mockups", "Data model" ], task.subtasks.pluck("text")

    task.toggle_subtask!(0)
    assert task.subtasks[0]["done"]
    assert_not task.subtasks[1]["done"]

    task.remove_subtask!(0)
    assert_equal [ "Data model" ], task.subtasks.pluck("text")
  end

  test "soft_delete! hides a task from kept without destroying it, restore! brings it back" do
    task = tasks(:read_chapter_three)
    task.soft_delete!
    assert_not_nil task.deleted_at
    assert_not_includes users(:one).tasks.kept, task
    assert Task.exists?(task.id)

    task.restore!
    assert_nil task.deleted_at
    assert_includes users(:one).tasks.kept, task
  end

  test "reorder_board! moves cards across statuses and sets their board position, scoped to the user" do
    other = users(:two).tasks.create!(title: "Not mine")
    mine = users(:one).tasks.create!(title: "Mine too")

    Task.reorder_board!(users(:one), {
      "pending" => [],
      "doing" => [ mine.id.to_s, tasks(:read_chapter_three).id.to_s ]
    })

    assert_equal %w[doing doing], [ mine, tasks(:read_chapter_three) ].map { |t| t.reload.status }
    assert_equal [ 0, 1 ], [ mine, tasks(:read_chapter_three) ].map { |t| t.reload.board_position }
    assert_equal "pending", other.reload.status, "another user's task must not move"
  end
end
