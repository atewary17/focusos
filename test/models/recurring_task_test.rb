require "test_helper"

class RecurringTaskTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert recurring_tasks(:daily_standup).valid?
    assert recurring_tasks(:weekend_only).valid?
  end

  test "due_today? checks the day of week and active flag" do
    sunday = Date.new(2026, 11, 8)
    monday = Date.new(2026, 11, 9)
    assert recurring_tasks(:weekend_only).due_today?(sunday)
    assert_not recurring_tasks(:weekend_only).due_today?(monday)

    recurring_tasks(:weekend_only).update!(active: false)
    assert_not recurring_tasks(:weekend_only).due_today?(sunday)
  end

  test "rejects an out-of-range day of week" do
    recurring_task = RecurringTask.new(user: users(:one), title: "x", days_of_week: [ 7 ])
    assert_not recurring_task.valid?
    assert_includes recurring_task.errors[:days_of_week], "must be between 0 and 6"
  end

  test "requires at least one day" do
    recurring_task = RecurringTask.new(user: users(:one), title: "x", days_of_week: [])
    assert_not recurring_task.valid?
  end

  test "generate_for! creates a task on a due day and is idempotent" do
    date = Date.new(2026, 11, 8) # Sunday
    recurring_task = recurring_tasks(:weekend_only)

    assert_difference -> { Task.count }, 1 do
      recurring_task.generate_for!(date)
    end
    task = recurring_task.tasks.sole
    assert_equal recurring_task.title, task.title
    assert_equal date, task.scheduled_on
    assert_equal recurring_task.subject, task.subject

    assert_no_difference -> { Task.count } do
      again = recurring_task.generate_for!(date)
      assert_equal task, again
    end
  end

  test "generate_for! does nothing on a day it isn't due" do
    monday = Date.new(2026, 11, 9)
    assert_nil recurring_tasks(:weekend_only).generate_for!(monday)
    assert_equal 0, recurring_tasks(:weekend_only).tasks.count
  end

  test "rejects a topic that belongs to another user" do
    recurring_task = RecurringTask.new(user: users(:one), title: "x", days_of_week: [ 1 ], topic: topics(:world_war_one))
    assert_not recurring_task.valid?
    assert_includes recurring_task.errors[:topic], "must belong to you"
  end

  test "self.generate_todays_tasks! generates only the active, due templates for that user" do
    date = Date.new(2026, 11, 8) # Sunday: both fixtures are due (standup is daily)

    tasks = RecurringTask.generate_todays_tasks!(users(:one), date)

    assert_equal [ recurring_tasks(:daily_standup).title ], tasks.map(&:title)
  end
end
