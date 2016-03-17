module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    def initialize(command)
      super(command)

      @pipelines = Escobar::Client.new(nil, client.token)
    end

    def self.help_documentation
      [
        "deploy -a APP - Display the last 10 releases for APP.",
        "deploy:info APP - View detailed information for a deployment."
      ]
    end

    def run
      @response = run_on_subtask
    end

    def run_on_subtask
      case subtask
      when "info"
        deploy_info
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

    def pipeline_markup(application, id)
      "<#{pipeline_link(id)}|#{application}>"
    end

    def pipeline_link(id)
      "https://dashboard.heroku.com/pipelines/#{id}"
    end

    def response_for_deploy(deploy)
      dashboard    = pipeline_markup(application, deploy.id)
      environments = deploy.environments.map do |name, apps|
        names = apps.map { |app| app.app.name }
        "#{name}: #{names.join(',')}"
      end.join("\n")

      {
        response_type: "in_channel",
        attachments: [
          {
            title: dashboard,
            fallback: "Heroku deploy for #{application}",
            text: environments,
            color: COLOR
          }
        ]
      }
    end
  end
end
