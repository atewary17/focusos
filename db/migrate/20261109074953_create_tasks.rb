class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :topic, foreign_key: true, index: true
      t.references :subject, foreign_key: true, index: true
      t.string :title, null: false
      t.text :notes
      t.string :lane, null: false, default: "backlog"
      t.integer :position, null: false, default: 0
      t.integer :priority
      t.date :due_on
      t.integer :estimate_minutes
      t.string :energy
      t.string :status, null: false, default: "pending"
      t.datetime :completed_at
      t.bigint :carried_from_id
      t.timestamps
    end
    add_index :tasks, %i[user_id lane position]
    add_foreign_key :tasks, :tasks, column: :carried_from_id
  end
end
