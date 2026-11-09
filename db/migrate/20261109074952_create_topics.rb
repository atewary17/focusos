class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :subject, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :status, null: false, default: "not_started"
      t.integer :estimated_minutes
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :topics, %i[subject_id position]
    add_index :topics, :user_id
  end
end
