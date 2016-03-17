class AddGithubToken < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :enc_github_token, :string, null: true
    add_column :users, :github_login, :string, null: true
  end
end
