class CreateCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_table :check_ins do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :device, null: false, foreign_key: true, index: false
      t.datetime :asked_at, null: false
      t.string :answer, null: false
      t.datetime :answered_at
      t.string :source
      t.timestamps
    end
    add_index :check_ins, %i[device_id asked_at], unique: true
    add_index :check_ins, %i[user_id asked_at]
  end
end
