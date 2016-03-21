# Module for handling Pipeline responses
module PipelineResponse
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
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
            }
          ]
        }
      ]
    }
  end
end
