# Job to handle heroku command execution
class CommandExecutorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    command_id = args.first.fetch(:command_id)
    user = args.first.fetch(:user)
    group = args.first.fetch(:group)
    command = Command.find(command_id)
    ExecuteCommand.for(command, user, group)
    Rails.logger.info "Executing Command #{command_id}"
    command.processed_at = Time.now.utc
    command.save
  end
end
