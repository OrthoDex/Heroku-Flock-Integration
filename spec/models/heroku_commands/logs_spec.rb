require "rails_helper"

RSpec.describe HerokuCommands::Logs, type: :model do
  include SlashHeroku::Support::Helpers::Api

  def heroku_handler_for(text)
    command = command_for(text)
    command.user.heroku_token = ENV["HEROKU_TOKEN"]
    command.user.save
    command.reload
    command.handler
  end

  # rubocop:disable Metrics/LineLength
  it "has a logs -a command" do
    command = heroku_handler_for("logs -a atmos-dot-org")
    logs_api_url = "https://logs-api.heroku.com/sessions/cc3cd8e9-8b2a-49ce-845d-c97ae6d0"

    stub_request(:get, "https://api.heroku.com/apps/atmos-dot-org/logs?logplex=true")
      .with(headers: default_headers(command.user.heroku_token, 2))
      .to_return(status: 200, body: "#{logs_api_url}?src=1457925552", headers: {})

    response_info = fixture_data("logs/atmos-dot-org/logs")
    stub_request(:get, logs_api_url)
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("logs")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("atmos-dot-org")
    expect { command.run }.to_not raise_error

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Heroku logs for atmos-dot-org")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(101)
    expect(attachment[:title])
      .to eql("<https://dashboard.heroku.com/apps/atmos-dot-org|atmos-dot-org> - Logs")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields]).to eql(nil)
  end
  # rubocop:enable Metrics/LineLength
end
