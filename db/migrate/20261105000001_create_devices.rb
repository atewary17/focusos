class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :installation_id, null: false
      t.string :name, null: false
      t.string :manufacturer
      t.string :model
      t.string :os_version
      t.string :app_version
      t.datetime :last_sync_at
      t.jsonb :last_sync_summary, null: false, default: {}
      t.jsonb :permissions, null: false, default: {}
      t.timestamps
    end
    add_index :devices, %i[user_id installation_id], unique: true
  end
end
