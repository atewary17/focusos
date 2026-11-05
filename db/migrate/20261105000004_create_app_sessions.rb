class CreateAppSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :device, null: false, foreign_key: true, index: false
      t.string :package_name, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.integer :duration_seconds, null: false
      t.timestamps
    end
    add_index :app_sessions, %i[device_id package_name started_at], unique: true
    add_index :app_sessions, %i[user_id started_at]
  end
end
