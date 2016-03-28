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

  def pipeline_markup
    "<#{pipeline.heroku_permalink}|#{application}>"
  end

  def repository_markup
    name_with_owner = pipeline.github_repository
    "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
  end

  def required_contexts_markup
    if pipeline.required_contexts.any?
      pipeline.required_contexts.map do |context|
        "<#{pipeline.default_branch_settings_uri}|#{context}>"
      end.join("\n")
    else
      "<#{pipeline.default_branch_settings_uri}|Add Required Contexts>"
    end
  end

  def app_names_for_pipeline_environment(name)
    apps = pipeline.environments[name]
    if apps && apps.any?
      apps.map { |app| app.app.name }.join("\n")
    else
      "<#{pipeline.heroku_permalink}|Create One>"
    end
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
          color: HerokuCommands::HerokuCommand::COLOR,
          fields: [
            {
              title: "Heroku",
              value: pipeline_markup,
              short: true
            },
            {
              title: "GitHub",
              value: repository_markup,
              short: true
            },
            {
              title: "Production Apps",
              value: app_names_for_pipeline_environment("production"),
              short: true
            },
            {
              title: "Staging Apps",
              value: app_names_for_pipeline_environment("staging"),
              short: true
            },
            {
              title: "Required Contexts",
              value: required_contexts_markup,
              short: true
            },
            {
              title: "Default Environment",
              value: pipeline.default_environment,
              short: true
            },
            {
              title: "Default Branch",
              value: pipeline.default_branch,
              short: true
            }
          ]
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
