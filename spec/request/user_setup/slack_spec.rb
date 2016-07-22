require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "creates a user when authenticated" do
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
  end
end
