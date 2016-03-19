module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    include ChatOpsPatterns

    attr_reader :info, :pipelines
    delegate :application, :branch, :environment, :forced, :hosts,
      :second_factor, to: :@info

    def initialize(command)
      super(command)

      @info = chat_deployment_request(command.command_text)
    end

    # rubocop:disable Metrics/LineLength
    def self.help_documentation
      [
        "deploy <app>/<branch> to <env>/<roles> - deploy pipeline <app>'s <branch> to the <env> environment's <roles>"
      ]
    end
    # rubocop:enable Metrics/LineLength

    def run
      @response = run_on_subtask
    end

    def pipelines
      @pipelines ||= pipelines!
    end

    def pipelines!
      if command.user.github_token
        Escobar::Client.new(command.user.github_token, client.token)
      end
    end

    def custom_payload
      {
        notify: {
          room: command.channel_name,
          user: command.user.slack_user_id,
          team_id: command.team_id,
          user_name: command.user.slack_user_name
        }
      }
    end

    # rubocop:disable Metrics/AbcSize
    def deploy_application
      if application && !pipelines[application]
        response_for("Unable to find a pipeline called #{application}")
      else

        pipeline   = pipelines[application]
        deployment = pipeline.create_deployment(branch, environment,
                                                forced, custom_payload)

        if deployment[:error]
          error_response_for(deployment[:error])
        else
          deployment[:command_id] = command.id
          DeploymentReaperJob.set(wait: 10.seconds).perform_later(deployment)
          nil
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def run_on_subtask
      case subtask
      when "default"
        if pipelines
          deploy_application
        else
          response_for("You're not authenticated with GitHub yet. " \
                       "<https://#{ENV['HOSTNAME']}/auth/github|Fix that>.")
        end
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      Rails.logger.info e.inspect
      response_for("Unable to fetch deployment info for #{application}.")
    end

    def pipeline_markup(application, deploy)
      "<#{pipeline_link(deploy.id)}|#{application}>"
    end

    def repository_markup(deploy)
      name_with_owner = deploy.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end

    def pipeline_link(id)
      "https://dashboard.heroku.com/pipelines/#{id}"
    end
  end
end
