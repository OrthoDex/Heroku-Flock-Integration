require "rails_helper"

RSpec.describe ExecuteCommand, type: :model do
  include Helpers::Command::Pipelines
  include Helpers::Command::Deploy
  include Helpers::Command::Releases

  describe "Deploy command" do
    before do
      Lock.clear_deploy_locks!
    end

    let(:command) { command_for("deploy hubot to production") }

    it "checks to make sure you're authenticated with heroku" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_heroku).to have_been_requested
    end

    it "checks to make sure you're authenticated with Github" do
      command.user.github_token = nil
      command.user.save

      stub_please_sign_into_github
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_github).to have_been_requested
    end

    it "deploys an app" do
      user = command.user
      user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
      user.save
      command.user.reload

      stub_deploy_command(command.user.heroku_token)

      expect(command.task).to eql("deploy")
      expect(command.subtask).to eql("default")

      # No real response, those are handled via github statuses and speakerboxxx
      slack_body = {}
      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end

  describe "Login command" do
    let(:command) { command_for("login") }

    it "logs you in if needed" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_heroku).to have_been_requested
    end
  end

  describe "Logout command" do
    let(:command) { command_for("logout") }

    it "logs you out" do
      response_info = fixture_data("api.heroku.com/account/info")
      stub_request(:get, "https://api.heroku.com/account")
        .with(headers: default_heroku_headers(command.user.heroku_token))
        .to_return(status: 200, body: response_info, headers: {})

      message = "Successfully removed your user. :wink:"
      slack_body = slack_body(message)
      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end

  describe "Pipelines command" do
    let(:command) { command_for("pipelines") }

    it "checks to make sure you're authenticated with heroku" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_heroku).to have_been_requested
    end

    it "checks to make sure you're authenticated with Github" do
      command.user.github_token = nil
      command.user.save

      stub_please_sign_into_github
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_github).to have_been_requested
    end

    it "lists available pipelines" do
      command.user.github_token = SecureRandom.hex(24)
      command.user.heroku_token = SecureRandom.hex(24)
      command.user.save

      stub_pipelines_command(command.user.heroku_token)

      message = "You can deploy: hubot, slash-heroku."
      slack_body = slack_body(message)
      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end

  describe "Releases command" do
    let(:command) { command_for("releases slash-heroku in staging") }

    before do
      Timecop.freeze(Time.zone.local(2017, 2, 1, 18, 0, 0))
    end

    after do
      Timecop.return
    end

    it "checks to make sure you're authenticated with heroku" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_heroku).to have_been_requested
    end

    it "checks to make sure you're authenticated with Github" do
      command.user.github_token = nil
      command.user.save

      stub_please_sign_into_github
      ExecuteCommand.for(command)
      expect(stub_please_sign_into_github).to have_been_requested
    end

    it "returns release information" do
      command.user.github_token = SecureRandom.hex(24)
      command.user.save

      stub_pipelines_command(command.user.heroku_token)

      stub_releases(command.user.heroku_token)

      # rubocop:disable Metrics/LineLength
      branch_link = "<https://github.com/atmos/slash-heroku/tree/more-debug-info|more-debug-info>"
      list_of_releases =
        "v149 - Deploy e046008 - #{branch_link} - corey@heroku.com - 16 days\n"\
        "v148 - Deploy 6464ae9 - #{branch_link} - corey@heroku.com - 16 days\n"\
        "v147 - Deploy 449afb0 - #{branch_link} - corey@heroku.com - 16 days\n"\
        "v146 - Update REDIS by heroku-redis - heroku-redis@addons.heroku.com - 17 days\n"\
        "v145 - Update DATABASE by heroku-postgresql - heroku-postgresql@addons.heroku.com - 17 days\n"\
        "v144 - Deploy edd2334 - #{branch_link} - corey@heroku.com - 18 days\n"\
        "v143 - Deploy f7c319e - #{branch_link} - corey@heroku.com - 18 days\n"\
        "v142 - Deploy f7c319e - #{branch_link} - corey@heroku.com - 19 days\n"\
        "v141 - Deploy ac0f775 - #{branch_link} - corey@heroku.com - 19 days\n"\
        "v140 - Deploy a2fa2f9 - <https://github.com/atmos/slash-heroku/tree/a2fa2f9|a2fa2f9> - corey@heroku.com - 19 days"

      title = "<https://dashboard.heroku.com/pipelines/slash-heroku|slash-heroku>"\
              " - Recent staging releases"

      # rubocop:enable Metrics/LineLength

      slack_body = {
        mrkdwn: true,
        response_type: "in_channel",
        attachments: [
          {
            color: "#6567a5",
            text: list_of_releases,
            title: title,
            fallback: "Latest releases for Heroku pipeline slash-heroku"
          }
        ]
      }.to_json

      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end

  def slack_body(message)
    {
      attachments:
        [
          {
            text: message
          }
        ]
    }.to_json
  end

  def stub_please_sign_into_heroku
    message = "Please <#{command.slack_auth_url}|sign in to Heroku>."
    slack_body = slack_body(message)
    stub_slack_request(slack_body)
  end

  def stub_please_sign_into_github
    message = "You're not authenticated with GitHub yet. " \
                "<#{command.github_auth_url}|Fix that>."
    slack_body = slack_body(message)
    stub_slack_request(slack_body)
  end
end
