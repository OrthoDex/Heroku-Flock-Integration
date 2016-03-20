require "rails_helper"

RSpec.describe "Linking with GitHub to create deployments", type: :request do
  before do
    OmniAuth.config.mock_auth[:slack]  = slack_omniauth_hash_for_atmos
    OmniAuth.config.mock_auth[:github] = github_omniauth_hash_for_atmos
    OmniAuth.config.mock_auth[:heroku] = heroku_omniauth_hash_for_atmos
  end

  it "authenticates GitHub after the initial setup" do
    get "/auth/slack"
    follow_redirect!

    get "/auth/github"
    follow_redirect!

    # /auth/complete
    expect(status).to eql(302)
    follow_redirect!

    # /auth/complete - thanks & goodbye
    expect(status).to eql(200)
    expect(body).to include("https://slack.com/messages")
  end
end
