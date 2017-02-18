# Job to handle heroku command execution
class CommandExecutorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    command_id = args.first.fetch(:command_id)
    command = Command.find(command_id)
    ExecuteCommand.for(command)
    command.processed_at = Time.now.utc
    command.save
  end
end
