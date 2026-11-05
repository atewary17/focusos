class CreateScreenEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :screen_events do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :device, null: false, foreign_key: true, index: false
      t.string :kind, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :screen_events, %i[device_id kind occurred_at], unique: true
    add_index :screen_events, %i[user_id occurred_at]
  end
end
