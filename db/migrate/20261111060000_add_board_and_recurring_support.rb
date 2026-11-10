# The status board (To-do/Doing/Done/Recurring) and the calendar both order
# cards by drag-and-drop, but along different axes (status vs. day), so each
# needs its own position column - sharing one `position` would let dragging
# on one view silently scramble the other.
class AddBoardAndRecurringSupport < ActiveRecord::Migration[8.1]
  def change
    rename_column :tasks, :position, :calendar_position
    add_column :tasks, :board_position, :integer, null: false, default: 0
    add_index :tasks, %i[user_id status board_position]

    create_table :recurring_tasks do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :topic, foreign_key: true, index: true
      t.references :subject, foreign_key: true, index: true
      t.string :title, null: false
      t.integer :estimate_minutes
      t.integer :priority
      t.string :energy
      t.integer :days_of_week, array: true, null: false, default: []
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_reference :tasks, :recurring_task, foreign_key: true, index: true
    add_index :tasks, %i[recurring_task_id scheduled_on], unique: true
  end
end
