module HerokuCommands
  # Class for listing available deployments
  class Where < HerokuCommand
    include PipelineResponse

    def initialize(command)
      super(command)

      pattern = /(where can i deploy|wcid)\s*([-_\.0-9a-z]+)/i
      matches = pattern.match(command.command_text)
      return unless matches
      command.application = matches[2]
    end

    def self.help_documentation
      [
        "where can i deploy - display the apps you can deploy from chat",
        "where can i deploy <app> - displays available environments for <app>"
      ]
    end

    def run
      @response = run_on_subtask
    end

    def new_pipeline_url
      "https://dashboard.heroku.com/pipelines/new"
    end

    def process_pipelines
      if pipelines.app_names.any?
        if application && pipelines[application]
          pipeline_info
        else
          response_for("You can deploy: #{pipelines.app_names.join(', ')}.")
        end
      else
        response_for("You don't have any pipelines yet, " \
                     "<#{new_pipeline_url}|Create one>.")
      end
    end

    def run_on_subtask
      case subtask
      when "default"
        if pipelines
          process_pipelines
        else
          response_for("You need to authenticate with GitHub in order to " \
                       "deploy. <#{command.github_auth_url}|Fix that>.")
        end
      else
        response_for("where:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      response_for("Unable to fetch deployment info for #{application}.")
    end
  end
end
