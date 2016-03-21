module HerokuCommands
  # Class for listing available deployments
  class Where < HerokuCommand
    def initialize(command)
      super(command)
    end

    def pipelines
      @pipelines ||= pipelines!
    end

    def pipelines!
      if command.user.github_token
        Escobar::Client.new(command.user.github_token, client.token)
      end
    end

    # rubocop:disable Metrics/LineLength
    def self.help_documentation
      [
        "where can i deploy - display the applications you can deploy from chat",
        "where can i deploy <app> - displays available environments for <app>",
        "wcid - display the applications you can deploy from chat",
        "wcid <app> - displays available environments for <app>"
      ]
    end
    # rubocop:enable Metrics/LineLength

    def run
      @response = run_on_subtask
    end

    def new_pipeline_url
      "https://dashboard.heroku.com/pipelines/new"
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/PerceivedComplexity
    def run_on_subtask
      case subtask
      when "default"
        if pipelines
          if pipelines.app_names.any?
            response_for("You can deploy: #{pipelines.app_names.join(', ')}.")
          else
            response_for("You don't have any pipelines yet, " \
                         "<#{new_pipeline_url}|Create one>.")
          end
        else
          response_for("You're not authenticated with GitHub yet. " \
                       "<#{command.github_auth_url}|Fix that>.")
        end
      else
        response_for("where:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      response_for("Unable to fetch deployment info for #{application}.")
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize
  end
end
