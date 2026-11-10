class AddDeletedAtToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :deleted_at, :datetime
    add_index :tasks, %i[user_id deleted_at]
  end
end
