module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
    include ChatOpsPatterns

    def initialize(command)
      super(command)

      @pipelines = Escobar::Client.new(nil, client.token)
    end

    def self.help_documentation
      [
        "pipelines:info -a APP - View detailed information for a pipeline."
      ]
    end

    def run
      @response = run_on_subtask
    end

    def run_on_subtask
      case subtask
      when "info"
        pipeline_info
      else
        response_for("pipeline:#{subtask} is currently unimplemented.")
      end
    rescue StandardError
      response_for("Unable to fetch pipeline info for #{application}.")
    end

    def pipeline_info
      response = @pipelines[application]
      response_for_pipeline(response)
    end

    def pipeline_markup(application, pipeline)
      "<#{pipeline_link(pipeline.id)}|#{application}>"
    end

    def repository_markup(pipeline)
      name_with_owner = pipeline.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end

    def pipeline_link(id)
      "https://dashboard.heroku.com/pipelines/#{id}"
    end

    def environment_output_for_pipeline(pipeline)
      pipeline.sorted_environments.map do |name|
        apps  = pipeline.environments[name]
        names = apps.map { |app| app.app.name }
        "#{name}: #{names.join(',')}"
      end.join("\n")
    end

    def response_for_pipeline(pipeline)
      repo_name = pipeline.github_repository
      {
        response_type: "in_channel",
        attachments: [
          {
            title: "Application: #{application}",
            fallback: "Heroku app #{application} (#{repo_name})",
            text: environment_output_for_pipeline(pipeline),
            color: COLOR,
            fields: [
              {
                title: "Heroku",
                value: pipeline_markup(application, pipeline),
                short: true
              },
              {
                title: "GitHub",
                value: repository_markup(pipeline),
                short: true
              }
            ]
          }
        ]
      }
    end
  end
end
