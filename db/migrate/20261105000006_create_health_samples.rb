class CreateHealthSamples < ActiveRecord::Migration[8.1]
  def change
    create_table :health_samples do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :device, null: false, foreign_key: true
      t.string :kind, null: false
      t.datetime :recorded_at, null: false
      t.datetime :end_at
      t.decimal :value, precision: 12, scale: 3, null: false
      t.string :unit, null: false
      t.string :source_package, null: false
      t.string :external_id
      t.timestamps
    end
    add_index :health_samples, %i[user_id kind recorded_at source_package], unique: true,
              name: "index_health_samples_uniqueness"
  end
end
