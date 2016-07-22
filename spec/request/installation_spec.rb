require "rails_helper"

RSpec.describe "Slack Application Installation", type: :request do
  it "creates a user and stores a token on the organization when installed" do
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

    expect(user.slack_user_name).to eql("atmos")
  end
end
