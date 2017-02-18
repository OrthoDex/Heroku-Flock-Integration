privacy_policy_url = ENV["PRIVACY_POLICY_URL"]

require "sidekiq/web"

Rails.application.routes.draw do
  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  get  "/auth/failure"         => "sessions#destroy"
  get  "/auth/complete"       => "sessions#complete"
  get  "/auth/github/callback" => "sessions#create_github"
  get  "/auth/heroku/callback" => "sessions#create_heroku"
  post  "/auth/flock/callback"  => "sessions#create_flock"
  # get  "/auth/flock_install/callback", to: "sessions#install_flock"

  get  "/health"   => "application#health"
  get  "/support"  => "pages#support"
  get  "/privacy", to: redirect(privacy_policy_url, status: 302)
  get  "/boomtown" => "application#boomtown"

  get "/commands" => "commands#create"
  post "/message_actions"  => "message_actions#create"
  post "/signout"  => "sessions#destroy"

  mount Sidekiq::Web => "/sidekiq"

  root to: "pages#install"
end
