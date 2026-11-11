class CreateSubjects < ActiveRecord::Migration[8.1]
  def change
    create_table :subjects do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :color, null: false, default: "#0f766e"
      t.integer :weekly_target_minutes
      t.integer :position, null: false, default: 0
      t.datetime :archived_at
      t.timestamps
    end
    add_index :subjects, %i[user_id position]
  end
end
