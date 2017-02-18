module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    attr_reader :info
    delegate :pipeline_name, :branch, :forced, :hosts, :second_factor,
      to: :@info

    def initialize(command)
      super(command)

      @info = ChatDeploymentInfo.from_text(command.command_text)
    end

    def self.help_documentation
        "deploy <pipeline>/<branch> to <stage>/<app-name> - " \
        "deploy a branch to a pipeline"
    end

    def run
      run_on_subtask
    end

    def environment
      @environment ||= info.environment || pipeline.default_environment
    end

    def deploy_application
      if pipeline_name && !pipeline
        response_for("Unable to find a pipeline called #{pipeline_name}")
      else
        DeploymentRequest.process(self)
      end
    end

    def deployment_complete_message(_payload, _sha)
      {}
    end

    def run_on_subtask
      case subtask
      when "default"
        deploy_application
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch deployment info for #{pipeline_name}.")
    end

    def repository_markup(deploy)
      name_with_owner = deploy.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end

    def pipeline
      user.pipeline_for(pipeline_name)
    end
  end
end
