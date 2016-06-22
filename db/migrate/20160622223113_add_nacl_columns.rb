class AddNaclColumns < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :nacl_enc_github_token, :string
    add_column :users, :nacl_enc_heroku_token, :string
    add_column :users, :nacl_enc_heroku_refresh_token, :string
  end
end
