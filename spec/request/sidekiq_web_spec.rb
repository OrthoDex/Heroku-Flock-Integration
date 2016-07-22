require "rails_helper"

RSpec.describe "Speakerboxxx GET /sidekiq", type: :request do
  it "404s if the user is not an administrator" do
    token = "xoxp-9101111159-5657146422-59735495733-3186a13efg"
    stub_json_request(:get,
                      "https://slack.com/api/users.identity?token=#{token}",
                      fixture_data("slack.com/identity.basic"))

    OmniAuth.config.mock_auth[:slack] = slack_omniauth_hash_for_non_admin
    expect do
      get "/auth/slack"
      expect(status).to eql(302)
      uri = Addressable::URI.parse(headers["Location"])
      expect(uri.host).to eql("www.example.com")
      expect(uri.path).to eql("/auth/slack/callback")
      follow_redirect!
    end.to change { User.count }.by(1)

    user = User.first

    expect(user.slack_user_name).to eql("fakeatmos")
    expect do
      get "/sidekiq"
    end.to raise_error(ActionController::RoutingError)
  end

  it "200s if the user is an administrator" do
    OmniAuth.config.mock_auth[:slack_install] = slack_omniauth_hash_for_atmos
    expect do
      get "/auth/slack_install"
      expect(status).to eql(302)
      uri = Addressable::URI.parse(headers["Location"])
      expect(uri.host).to eql("www.example.com")
      expect(uri.path).to eql("/auth/slack_install/callback")
      follow_redirect!
    end.to change { User.count }.by(1)

    user = User.first
    user.update(github_login: "atmos")

    expect(user.github_login).to eql("atmos")
    expect(user.slack_user_name).to eql("atmos")
    get "/sidekiq"
    expect(status).to eql(200)
  end
end
