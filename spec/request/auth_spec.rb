require "rails_helper"

RSpec.describe "Authentication", type: :request do
  before do
    OmniAuth.config.mock_auth[:slack]  = slack_omniauth_hash_for_atmos
    OmniAuth.config.mock_auth[:github] = github_omniauth_hash_for_atmos
    OmniAuth.config.mock_auth[:heroku] = heroku_omniauth_hash_for_atmos
  end
end
