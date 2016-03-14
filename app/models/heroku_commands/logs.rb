module HerokuCommands
  # Class for handling logout and identity information
  class Logs < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "logs -a APP - Display the last 1000 lines of logs."
      ]
    end

    def run
      @response = if application
                    logs_for(application)
                  else
                    help_for_task
                  end
    end

    def logs_for(application)
      response = client.logs_for(application)
      response_for_logs(response)
    rescue StandardError
      response_for("Unable to fetch logs for #{application}.")
    end

    def dashboard_markup(application)
      "<#{dashboard_link(application)}|#{application}>"
    end

    def dashboard_link(application)
      "https://dashboard.heroku.com/apps/#{application}"
    end

    def response_for_logs(logs)
      dashboard = dashboard_markup(application)
      {
        response_type: "in_channel",
        attachments: [
          {
            text: logs,
            color: COLOR,
            title: "#{dashboard} - Logs",
            fallback: "Heroku logs for #{application}"
          }
        ]
      }
    end
  end
end
