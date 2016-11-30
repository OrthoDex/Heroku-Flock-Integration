ENV["APP_NAME"] = "slash-heroku"
ENV["HOSTNAME"] = "www.example.com"
ENV["SLACK_APP_URL"] = "https://slack.com/apps/manage/A0SFS6WSD-heroku"
ENV["KOLKRABBI_HOSTNAME"] = "kolkrabbi.com"
ENV["PRIVACY_POLICY_URL"] = "https://www.example.com/privacy.html"
ENV["SLACK_SLASH_COMMAND_TOKEN"] = "secret-slack-token"
ENV["FERNET_SECRET"] = "2bb0Wq1HJDPg2eLRnvTbKh8xPtJzqJnonOi3fDyVIJ8="
ENV["GITHUB_ADMIN_LOGINS"] = "atmos"

require "webmock/rspec"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(WebMock::API)

  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!
  end
end
