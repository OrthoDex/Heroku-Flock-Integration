# A user from the Flock API
class User < ApplicationRecord
  include TokenManagement
  include GitHubTokenManagement
  include HerokuTokenManagement

  has_many :commands, dependent: :destroy
  has_many :message_actions, dependent: :destroy

  def self.omniauth_user_data(omniauth_info)
    token = omniauth_info[:credentials][:token]
    response = flock_client.get("/api/users.identity?token=#{token}")

    JSON.parse(response.body)
  end

  def self.from_omniauth(omniauth_info)
    body = omniauth_user_data(omniauth_info)

    user = find_or_initialize_by(
      flock_user_id: body["user"]["id"]
    )
    user.flock_team_id   = body["team"]["id"]
    user.flock_user_name = body["user"]["name"]
    user.save
    user
  end

  def self.flock_client
    Faraday.new(url: "https://api.flock.co/v1/") do |connection|
      connection.headers["Content-Type"] = "application/json"
      connection.use :instrumentation
      connection.use ZipkinTracer::FaradayHandler, "flock.co"
      connection.adapter Faraday.default_adapter
    end
  end

  def pipeline_for(pipeline_name)
    return unless pipelines
    pipelines[pipeline_name]
  end

  def onboarded?
    heroku_configured? && github_configured?
  end

  def pipelines
    return unless onboarded?
    @pipelines ||= Escobar::Client.new(github_token, heroku_token)
  end

  def heroku_user_information
    return nil unless heroku_configured?
    pipelines.heroku.user_information
  end

  def create_command_for(params, user, group)
    command = commands.create(
      command: params[:command],
      command_text: params[:text]
    )
    CommandExecutorJob.perform_later(command_id: command.id, user: user, group: group)
    # YubikeyExpireJob.set(wait: 10.seconds).perform_later(command_id: command.id)
    command
  end

  def create_message_action_for(params)
    channel = params[:channel]
    team = params[:team]
    action = create_message_action_for_team_and_channel(team, channel, params)
    MessageActionExecutorJob.perform_later(action_id: action.id)
    action
  end

  def create_message_action_for_team_and_channel(team, channel, params)
    button_clicked = params[:actions][0]
    message_actions.create(
      action_ts: params[:action_ts],
      callback_id: params[:callback_id],
      channel_id: channel[:id],
      channel_name: channel[:name],
      message_ts: params[:message_ts],
      response_url: params[:response_url],
      team_domain: team[:domain],
      team_id: team[:id],
      value: button_clicked[:value]
    )
  end
end
