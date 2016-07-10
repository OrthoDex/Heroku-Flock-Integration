module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
    include ChatOpsPatterns
    include PipelineResponse

    def initialize(command)
      super(command)
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
    rescue StandardError => e
      if Rails.env.test?
        raise e
      else
        Rollbar.report(e)
      end
      response_for("Unable to fetch pipeline info for #{application}.")
    end
  end
end
