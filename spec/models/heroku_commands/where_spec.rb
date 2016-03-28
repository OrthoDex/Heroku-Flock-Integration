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
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
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
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("where")
    expect(command.subtask).to eql("default")
    expect(command.application).to be_nil

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to eql("You can deploy: hubot, slash-heroku.")
  end

  it "lists available environments for named pipeline" do
    command = heroku_handler_for("where can i deploy slash-heroku")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_request(:get, "https://api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
      .with(headers: default_github_headers(command.user.github_token))
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
      .with(headers: default_github_headers(command.user.github_token))
      .to_return(status: 200, body: response, headers: {})

    expect(command.task).to eql("where")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("slash-heroku")

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Heroku app slash-heroku (atmos/slash-heroku)")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text]).to be_nil
    expect(attachment[:title]).to eql("Application: slash-heroku")
    expect(attachment[:title_link]).to eql(nil)

    heroku_cell = attachment[:fields][0]
    expect(heroku_cell).to_not be_nil
    expect(heroku_cell[:title]).to eql("Heroku")
    expect(heroku_cell[:value]).to eql("<https://dashboard.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc|slash-heroku>")

    github_cell = attachment[:fields][1]
    expect(github_cell).to_not be_nil
    expect(github_cell[:title]).to eql("GitHub")
    expect(github_cell[:value]).to eql("<https://github.com/atmos/slash-heroku|atmos/slash-heroku>")

    branch_cell = attachment[:fields][2]
    expect(branch_cell).to_not be_nil
    expect(branch_cell[:title]).to eql("Default Branch")
    expect(branch_cell[:value]).to eql("master")

    required_contexts_cell = attachment[:fields][3]
    expect(required_contexts_cell).to_not be_nil
    expect(required_contexts_cell[:title]).to eql("Required Contexts")
    expect(required_contexts_cell[:value]).to eql("<https://github.com/atmos/slash-heroku/settings/branches/master|continuous-integration/travis-ci/push>")

    production_cell = attachment[:fields][4]
    expect(production_cell).to_not be_nil
    expect(production_cell[:title]).to eql("Production Environment")
    expect(production_cell[:value]).to eql("slash-heroku-production")

    staging_cell = attachment[:fields][5]
    expect(staging_cell).to_not be_nil
    expect(staging_cell[:title]).to eql("Staging Environment")
    expect(staging_cell[:value]).to eql("slash-heroku-staging")
  end
  # rubocop:enable Metrics/LineLength
end
