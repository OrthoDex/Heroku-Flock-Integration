class FixupSlackUserIds < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :commands, :users
    change_column :commands, :user_id, :uuid, null: true
  end
end
