# Job to handle kicking off a Deployment request
class DeploymentReaperJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  def perform(*args_list)
    args = args_list.first

    sha            = args.fetch(:sha)
    repo           = args.fetch(:repo)
    name           = args.fetch(:name)
    app_id         = args.fetch(:app_id)
    build_id       = args.fetch(:build_id)
    command_id     = args.fetch(:command_id)
    deployment_url = args.fetch(:deployment_url)

    command = Command.find(command_id)
    handler = command.handler

    pipeline = handler.pipelines[name]
    info = pipeline.reap_build(app_id, build_id)
    if info
      Rails.logger.info "Build Complete: #{info.to_json}"

      state = "failure"
      state = "success" if info["status"] == "succeeded"
      payload = {
        state: state,
        target_url:  "https://dashboard.heroku.com/apps/#{app_id}/activity/builds/#{build_id}",
        description: "Chat deployment complete. slash-heroku"
      }
      pipeline.create_deployment_status(deployment_url, payload)
    elsif command.created_at > 2.minutes.ago
      DeploymentReaperJob.set(wait: 10.seconds).perform_later(args)
    else
      Rails.logger.info "Build expired for command: #{command.id}"
      payload = {
        state: "failure",
        target_url:  "https://dashboard.heroku.com/apps/#{app_id}/activity/builds/#{build_id}",
        description: "Heroku build took longer than 5 minutes."
      }
      pipeline.create_deployment_status(deployment_url, payload)
    end
  rescue StandardError => e
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/LineLength
end
