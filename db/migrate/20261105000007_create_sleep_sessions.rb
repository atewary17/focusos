class CreateSleepSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sleep_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :device, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.string :source_package, null: false
      t.string :external_id
      t.jsonb :stages, null: false, default: []
      t.timestamps
    end
    add_index :sleep_sessions, %i[user_id source_package started_at], unique: true,
              name: "index_sleep_sessions_uniqueness"
  end
end
