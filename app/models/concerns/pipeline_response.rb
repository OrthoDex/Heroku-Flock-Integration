# Module for handling Pipeline responses
module PipelineResponse
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def pipeline
    pipelines[application]
  end

  def pipelines
    @pipelines ||= pipelines!
  end

  def pipelines!
    if command.user.github_token
      Escobar::Client.new(command.user.github_token, client.token)
    end
  end

  def pipeline_info
    response_for_pipeline(pipeline)
  end

  def pipeline_markup(application, pipeline)
    "<#{pipeline.heroku_permalink}|#{application}>"
  end

  def repository_markup(pipeline)
    name_with_owner = pipeline.github_repository
    "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
  end

  def required_contexts_markup(pipeline)
    if pipeline.required_contexts.any?
      pipeline.required_contexts.join("\n")
    else
      "<#{pipeline.default_branch_settings_uri}|Add Required Contexts>"
    end
  end

  def environment_output_for_pipeline(pipeline)
    pipeline.sorted_environments.map do |name|
      apps  = pipeline.environments[name]
      names = apps.map { |app| app.app.name }
      "#{name}: #{names.join(',')}"
    end.join("\n")
  end

  # rubocop:disable Metrics/MethodLength
  def response_for_pipeline(pipeline)
    repo_name = pipeline.github_repository
    {
      response_type: "in_channel",
      attachments: [
        {
          title: "Application: #{application}",
          fallback: "Heroku app #{application} (#{repo_name})",
          text: environment_output_for_pipeline(pipeline),
          color: HerokuCommands::HerokuCommand::COLOR,
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
            },
            {
              title: "Default Branch",
              value: pipeline.default_branch,
              short: true
            },
            {
              title: "Required Contexts",
              value: required_contexts_markup(pipeline),
              short: true
            }
          ]
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
