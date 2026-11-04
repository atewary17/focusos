class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :time_zone, :string, null: false, default: "Asia/Kolkata"
    add_column :users, :consented_at, :datetime
  end
end
