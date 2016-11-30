# Job to handle heroku action execution
class ActionExecutorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    action_id = args.first.fetch(:action_id)
    action = Action.find(action_id)
  end
end
