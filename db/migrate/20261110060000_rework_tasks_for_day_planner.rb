# The board moved from status lanes to day columns (see docs/HANDOFF.md P2/P3):
# a task is scheduled onto a specific day, optionally a specific time, and can
# carry a small subtask checklist.
class ReworkTasksForDayPlanner < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :scheduled_on, :date
    add_column :tasks, :starts_at, :datetime
    add_column :tasks, :subtasks, :jsonb, null: false, default: []
    add_index :tasks, %i[user_id scheduled_on position]

    remove_column :tasks, :lane, :string, null: false, default: "backlog"
  end
end
