class CreateAppUsageDays < ActiveRecord::Migration[8.1]
  def change
    create_table :app_usage_days do |t|
      t.references :user, null: false, foreign_key: true
      t.references :device, null: false, foreign_key: true, index: false
      t.date :date, null: false
      t.string :package_name, null: false
      t.string :app_label
      t.integer :foreground_seconds, null: false, default: 0
      t.integer :launches, null: false, default: 0
      t.datetime :first_used_at
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :app_usage_days, %i[device_id package_name date], unique: true
    add_index :app_usage_days, %i[user_id date]
  end
end
