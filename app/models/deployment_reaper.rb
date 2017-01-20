# Heroku deployment build reaper
class DeploymentReaper
  attr_reader :args, :sha, :repo, :app_name,
    :build_id, :command_id, :deployment_url

  def self.run(args)
    reaper = new(args)
    reaper.reap
    reaper
  end

  def initialize(args = {})
    @args           = args
    @sha            = args.fetch(:sha)
    @repo           = args.fetch(:repo)
    @app_name       = args.fetch(:app_name)
    @build_id       = args.fetch(:build_id)
    @command_id     = args.fetch(:command_id)
    @deployment_url = args.fetch(:deployment_url)
  end

  def reap
    if build
      if build.releasing?
        reap_release
      else
        build_completed
      end
    elsif command_is_still_running?
      DeploymentReaperJob.set(wait: 10.seconds).perform_later(args)
    else
      build_expired
    end
  end

  def build
    @build ||= pipeline.reap_build(app_name, build_id)
  end

  private

  def build_expired
    Rails.logger.info "Build expired for command: #{command.id}"
    payload = {
      state: "failure",
      target_url:  build_url(app_name, build_id),
      description: "Heroku build took longer than 15 minutes."
    }
    pipeline.create_deployment_status(deployment_url, payload)
  end

  def command_is_still_running?
    command.created_at > 15.minutes.ago
  end

  def reap_release
    Rails.logger.info "Build Complete: #{artifact.to_json}. Releasing..."
    payload = {
      state: "pending",
      target_url:  build_url(app_name, build_id),
      description: "Build phase completed. Running release phase."
    }
    pipeline.create_deployment_status(deployment_url, payload)
    ReleaseReaperJob.perform_later(
      args.merge(release_id: build.release_id)
    )
  end

  def build_completed
    Rails.logger.info "Build Complete: #{artifact.to_json}."
    payload = {
      state: "failure",
      target_url:  build_url(app_name, build_id),
      description: "Build phase completed. slash-heroku"
    }
    payload[:state] = "success" if build.status == "succeeded"

    pipeline.create_deployment_status(deployment_url, payload)
  end

  def command
    Command.find(command_id)
  end

  def pipeline
    command.handler.pipeline
  end

  def slug_id
    build.info && build.info["slug"] && build.info["slug"]["id"]
  end

  def artifact
    { sha: sha, slug: slug_id, repo: repo }
  end

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end
end
