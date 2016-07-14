require "rails_helper"

RSpec.describe "Linking with GitHub to create deployments", type: :request do
  before do
    token = "xoxp-9101111159-5657146422-59735495733-3186a13efg"
    stub_json_request(:get,
                      "https://slack.com/api/users.identity?token=#{token}",
                      fixture_data("slack.com/identity.basic"))

    OmniAuth.config.mock_auth[:slack]  = slack_omniauth_hash_for_non_admin
    OmniAuth.config.mock_auth[:github] = github_omniauth_hash_for_atmos
    OmniAuth.config.mock_auth[:heroku] = heroku_omniauth_hash_for_atmos
  end

  it "authenticates GitHub after the initial setup" do
    command = command_for("ps")

    # Calling back from Slack's OAuth handshake
    get "/auth/github?origin=#{command.encoded_origin_hash(:github)}"
    follow_redirect!

    # 302s to Slack OAuth
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/slack")
    follow_redirect!

    # 302s to Slack OAuth callback
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/slack/callback")
    follow_redirect!

    # 302s to GitHub OAuth
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/github")
    follow_redirect!

    # 302s to GitHub OAuth Callback
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/github/callback")
    follow_redirect!

    ## /auth/complete
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/complete")
    follow_redirect!

    ## /auth/complete - thanks & goodbye
    expect(status).to eql(200)
    expect(body).to include("slack://channel?team=T123YG08V&id=C99NNAY74")
  end
end
