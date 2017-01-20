require "rails_helper"

RSpec.describe DeploymentReaper, type: :model do
  include SlashHeroku::Support::Helpers::Api

  let(:user) do
    u = create_atmos
    u.heroku_token = SecureRandom.hex(24)
    u.heroku_refresh_token = SecureRandom.hex(16)
    u.heroku_expires_at = 15.minutes.from_now
    u.github_token = SecureRandom.hex(24)
    u.save
    u
  end

  let(:deployment_url) do
    "https://api.github.com/repos/atmos/slash-heroku/deployments/123456"
  end

  # rubocop:disable Metrics/LineLength
  it "successfully reaps a build with a release" do
    args = {
      sha: "abcdefg",
      repo: "heroku/slash-heroku",
      app_name: "slash-h-production",
      build_id: "b80207dc-139f-4546-aedc-985d9cfcafab",
      deployment_url: deployment_url
    }

    command = user.create_command_for(command_params_for("deploy slash-heroku to prod"))

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{args[:build_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{args[:build_id]}")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    stub_request(:post, "#{deployment_url}/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})

    reaper = DeploymentReaper.run(args.merge(command_id: command.id))
    expect(reaper.build.status).to eql("succeeded")
    expect(reaper.build).to be_releasing
  end
  # rubocop:enable Metrics/LineLength
end
