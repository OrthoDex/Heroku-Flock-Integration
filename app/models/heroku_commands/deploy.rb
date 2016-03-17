module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    # Class for encapsulating a chat deployment request
    class Deployment
      include ChatOpsPatterns
      attr_reader :application, :branch, :environment, :forced,
        :hosts, :second_factor
      def initialize(command, string)
        @string  = string
        @command = command

        matches = deploy_pattern.match(string)
        if matches
          @forced        = matches[2] == "!"
          @application   = matches[3]
          @branch        = matches[4] || "master"
          @environment   = matches[5] || "staging"
          @hosts         = matches[6]
          @second_factor = matches[7]
        end
      end
    end

    attr_reader :info, :pipelines
    delegate :application, :branch, :environment, :forced, :hosts,
      :second_factor, to: :@info

    def initialize(command)
      super(command)

      @info = Deployment.new(self, command.command_text)
      @pipelines = Escobar::Client.new(nil, client.token)
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

    def deploy_application
      if application && !pipelines[application]
        response_for("Unable to find a pipeline called #{application}")
      else
        response_for("Should've deployed #{application} to #{environment}.")
      end
    end

    def run_on_subtask
      case subtask
      when "info"
        deploy_info
      when "default"
        deploy_application
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError
      response_for("Unable to fetch deployment info for #{application}.")
    end

    def deploy_info
      response = @pipelines[application]
      response_for_deploy(response)
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

    def environment_output_for_deploy(deploy)
      deploy.sorted_environments.map do |name|
        apps  = deploy.environments[name]
        names = apps.map { |app| app.app.name }
        "#{name}: #{names.join(',')}"
      end.join("\n")
    end

    def response_for_deploy(deploy)
      github_dashboard = repository_markup(deploy)
      heroku_dashboard = pipeline_markup(application, deploy)
      {
        response_type: "in_channel",
        attachments: [
          {
            title: "Application: #{application}",
            fallback: "Heroku app #{application} (#{deploy.github_repository})",
            text: environment_output_for_deploy(deploy),
            color: COLOR,
            fields: [
              {
                title: "Heroku",
                value: heroku_dashboard,
                short: true
              },
              {
                title: "GitHub",
                value: github_dashboard,
                short: true
              }
            ]
          }
        ]
      }
    end
  end
end
