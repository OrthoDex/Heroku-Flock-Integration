Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_OAUTH_ID"], ENV["GITHUB_OAUTH_SECRET"], scope: "user,repo"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :heroku, ENV["HEROKU_OAUTH_ID"], ENV["HEROKU_OAUTH_SECRET"], scope: "global", fetch_info: true
end

OmniAuth.config.logger = Rails.logger
