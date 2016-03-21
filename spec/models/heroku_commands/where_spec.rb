require "rails_helper"

RSpec.describe HerokuCommands::Where, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "makes you sign up for GitHub OAuth" do
    command = heroku_handler_for("where can i deploy")
    message = "You're not authenticated with GitHub yet. " \
                "<https://www.example.com/auth/github([^|]+)|Fix that>."

    expect(command.task).to eql("where")
    expect(command.subtask).to eql("default")
    expect(command.application).to be_nil

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to match(Regexp.new(message))
    expect(command.response[:attachments]).to be_nil
  end

  # rubocop:disable Metrics/LineLength
  it "tells you to create a pipeline if no pipelines exist" do
    command = heroku_handler_for("where can i deploy")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_headers(command.user.heroku_token))
      .to_return(status: 200, body: [].to_json, headers: {})

    expect(command.task).to eql("where")
    expect(command.subtask).to eql("default")
    expect(command.application).to be_nil

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text])
      .to eql("You don't have any pipelines yet, <https://dashboard.heroku.com/pipelines/new|Create one>.")
  end

  it "lists available pipelines you can deploy to" do
    command = heroku_handler_for("where can i deploy")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

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

    expect(command.task).to eql("where")
    expect(command.subtask).to eql("default")
    expect(command.application).to be_nil

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to eql("You can deploy: hubot, slash-heroku.")
  end
  # rubocop:enable Metrics/LineLength
end
