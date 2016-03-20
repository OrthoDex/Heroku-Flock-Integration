class AddSlackUserIdToCommands < ActiveRecord::Migration[5.0]
  def change
    add_column :commands, :slack_user_id, :string, null: true
  end
end
