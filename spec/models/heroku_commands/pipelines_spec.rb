require "rails_helper"

RSpec.describe HerokuCommands::Pipelines, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  # rubocop:disable Metrics/LineLength
  it "has a pipeline:info command" do
    command = heroku_handler_for("pipelines:info -a hubot")

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

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("info")
    expect(command.application).to eql("hubot")

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Heroku app hubot (atmos/hubot)")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(1)
    expect(attachment[:title]).to eql("Application: hubot")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields].size).to eql(2)

    fields = attachment[:fields]
    expect(fields.first[:title]).to eql("Heroku")
    expect(fields.first[:value]).to eql("<https://dashboard.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111|hubot>")
    expect(fields.last[:title]).to eql("GitHub")
    expect(fields.last[:value]).to eql("<https://github.com/atmos/hubot|atmos/hubot>")
  end
end
