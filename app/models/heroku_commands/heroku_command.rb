# Namespace for containing HerokuCommands
module HerokuCommands
  # Top-level class for implementing Heroku commands
  class HerokuCommand
    include ActionView::Helpers::DateHelper

    COLOR = "#6567a5".freeze
    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    attr_reader :command
    delegate :application, :subtask, :task, :user, to: :@command

    def initialize(command)
      @command = command
    end

    def run
      # Overridden in each subclass
    end

    def self.help_documentation
      []
    end

    def help_for_task
      "Run /heroku help <task> for task specific help: \n
      #{self.class.help_documentation.join("\n")}"
    end

    def error_response_for(text)
      { response_type: "in_channel",
        attachments: [{ text: text, color: "#f00" }] }
    end

    def error_response_for_escobar_two_factor(error)
      "<#{error.dashboard_url}|Unlock \n#{error.build_request.app.name}>"
    end

    def error_response_for_escobar_known_exception(error)
      error.message
    end

    def error_response_for_escobar(error)
      case error.message
      when /Commit status checks failed/i
        error_response_for_escobar_known_exception(error)
      when /requires second factor/i
        error_response_for_escobar_two_factor(error)
      when /Unable to create heroku build/i
        error_response_for_escobar_known_exception(error)
      else
        Raven.capture_exception(error)
        Rails.logger.info source: :escobar, error: error.message
        {}
      end
    end

    def response_for(text)
      text
    end
  end
end
