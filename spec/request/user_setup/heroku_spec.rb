require "rails_helper"

RSpec.describe "Initial setup & linking with Heroku", type: :request do
  before do
    token = "xoxp-9101111159-5657146422-59735495733-3186a13efg"
    stub_json_request(:get,
                      "https://slack.com/api/users.identity?token=#{token}",
                      fixture_data("slack.com/identity.basic"))

    OmniAuth.config.mock_auth[:slack]  = slack_omniauth_hash_for_non_admin
    OmniAuth.config.mock_auth[:heroku] = heroku_omniauth_hash_for_atmos
  end

  it "sends you back to your chat via HTTPS after authenticating" do
    # Calling back from Slack's OAuth handshake
    get "/auth/slack"
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/slack/callback")
    follow_redirect!

    # 302s to Heroku OAuth if Slack succeeds
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku")
    follow_redirect!

    # Calling back from Heroku's OAuth handshake
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku/callback")
    follow_redirect!

    # /auth/complete
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/complete")
    follow_redirect!

    # /auth/complete - thanks & goodbye
    expect(status).to eql(200)
    expect(body).to include("https://slack.com/messages")
  end

  it "preserves the origin parameter to redirect back to native apps" do
    command = command_for("ps")

    # Calling back from Slack's OAuth handshake
    get "/auth/slack?origin=#{command.encoded_origin_hash}"
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/slack/callback")
    follow_redirect!

    # 302s to Heroku OAuth if Slack succeeds
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku")
    follow_redirect!

    # Calling back from Heroku's OAuth handshake
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku/callback")
    follow_redirect!

    # /auth/complete
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/complete")
    follow_redirect!

    # /auth/complete - thanks & goodbye
    expect(status).to eql(200)
    expect(body).to include("slack://channel?team=T123YG08V&id=C99NNAY74")
  end

  it "detects and rejects malformed origin parameters in signup" do
    origin = Base64.encode64(JSON.dump(uri: "https://www.google.com/"))

    # Calling back from Slack's OAuth handshake
    get "/auth/slack?origin=#{origin}"
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/slack/callback")
    follow_redirect!

    # 302s to Heroku OAuth if Slack succeeds
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku")
    follow_redirect!

    # Calling back from Heroku's OAuth handshake
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/heroku/callback")
    follow_redirect!

    # /auth/complete
    expect(status).to eql(302)
    uri = Addressable::URI.parse(headers["Location"])
    expect(uri.host).to eql("www.example.com")
    expect(uri.path).to eql("/auth/complete")
    follow_redirect!

    # /auth/complete - thanks & goodbye
    # Goes to messages since the URI doesn't start with slack://
    expect(status).to eql(200)
    expect(body).to include("https://slack.com/messages")
  end
end
