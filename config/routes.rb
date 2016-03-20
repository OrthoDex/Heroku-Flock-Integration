applcation_url = ENV["SLACK_APP_URL"] || "https://github.com/atmos/slash-heroku"

Rails.application.routes.draw do
  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  get  "/auth/failure"         => "sessions#destroy"
  get  "/auth/complete"        => "sessions#complete"
  get  "/auth/github/callback" => "sessions#create_github"
  get  "/auth/heroku/callback" => "sessions#create_heroku"
  get  "/auth/slack/callback"  => "sessions#create_slack"

  get  "/install"  => "pages#install"
  get  "/support"  => "pages#support"
  get  "/boomtown" => "application#boomtown"

  post "/commands" => "commands#create"
  post "/signout"  => "sessions#destroy"

  root to: redirect(applcation_url, status: 302)
end
