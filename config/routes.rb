applcation_url     = ENV["SLACK_APP_URL"] || "https://github.com/atmos/slash-heroku"
privacy_policy_url = ENV["PRIVACY_POLICY_URL"] || "https://api.slack.com/developer-policy"

Rails.application.routes.draw do
  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  get  "/auth/failure"         => "sessions#destroy"
  get  "/auth/complete"        => "sessions#complete"
  get  "/auth/github/callback" => "sessions#create_github"
  get  "/auth/heroku/callback" => "sessions#create_heroku"
  get  "/auth/slack/callback"  => "sessions#create_slack"

  get  "/health"   => "application#health"
  get  "/install"  => "pages#install"
  get  "/support"  => "pages#support"
  get  "/privacy", to: redirect(privacy_policy_url, status: 302)
  get  "/boomtown" => "application#boomtown"

  post "/commands" => "commands#create"
  post "/signout"  => "sessions#destroy"

  root to: redirect(applcation_url, status: 302)
end
