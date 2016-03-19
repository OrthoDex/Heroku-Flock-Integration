require "rails_helper"

RSpec.describe HerokuCommands::Deploy, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  # rubocop:disable Metrics/LineLength
  it "has a deploy command" do
    command = heroku_handler_for("deploy hubot")

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
    stub_request(:get, "https://api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.github.com/repos/atmos/hubot/tarball/master")
    stub_request(:head, "https://api.github.com/repos/atmos/hubot/tarball/master")
      .to_return(status: 200, body: response_info, headers: { "Location" => "https://codeload.github.com/atmos/hubot/legacy.tar.gz/master" })

    deployment_response = { sha: "27bd10a885d27ba4db2c82dd34a199b6a0a8149c" }.to_json
    stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments")
      .to_return(status: 200, body: deployment_response, headers: {})

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("hubot")

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to eql("Should've deployed hubot to staging.")
    expect(command.response[:attachments]).to be_nil
  end
end
