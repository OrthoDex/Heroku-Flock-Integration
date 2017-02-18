# Generates command body and posts it to flock
class ExecuteCommand
  attr_reader :command, :task

  REQUIRES_AUTHENTICATION = %w{pipeline pipelines deploy releases}.freeze

  def self.for(command, user)
    new(command, user).post_to_flock
  end

  def initialize(command, user)
    @command = command
    @task = command.task
    @user = user
  end

  def post_to_flock
    Rails.logger.info "Posting to Flock"
    FlockPostback.for(response, @user)
  end

  def response
    handler.run
  end

  def handler
    if logging_in || needs_authentication
      Rails.logger.info "In handler for Heroku login"
      HerokuCommands::Login.new(command)
    else
      task_handler
    end
  end

  def task_handler
    Rails.logger.info "In task handler"
    case task
    when "deploy"
      HerokuCommands::Deploy.new(command)
    when "logout"
      HerokuCommands::Logout.new(command)
    when "pipeline", "pipelines"
      HerokuCommands::Pipelines.new(command)
    when "releases"
      HerokuCommands::Releases.new(command)
    else # when "help"
      HerokuCommands::Help.new(command)
    end
  end

  def needs_authentication
    REQUIRES_AUTHENTICATION.include?(task) && not_setup?
  end

  def logging_in
    task == "login"
  end

  def not_setup?
    !command.user.onboarded?
  end
end
