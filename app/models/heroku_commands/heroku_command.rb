# Namespace for containing HerokuCommands
module HerokuCommands
  # Top-level class for implementing Heroku commands
  class HerokuCommand
    include ActionView::Helpers::DateHelper

    COLOR = "#6567a5".freeze
    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    attr_reader :client, :command, :description, :response
    delegate :application, :subtask, :task, :user, to: :@command

    def initialize(command)
      @command  = command
      @client   = ::HerokuApi.new(user.heroku_token)

      @description = command.description.gsub("Running", "Ran")
      @response    = { text: description, response_type: "in_channel" }
    end

    def run
      # Overridden in each subclass
    end

    def self.help_documentation
      []
    end

    def help_for_task
      {
        response_type: "in_channel",
        attachments: [
          {
            text: self.class.help_documentation.join("\n"),
            pretext: "Run /h help releases for task specific help",
            fallback: "Help commands from the heroku integration",
            title: "Available heroku #{task} commands:",
            title_link: "https://github.com/atmos/slash-heroku#slashheroku-"
          }
        ]
      }
    end

    def error_response_for(text)
      { response_type: "in_channel",
        attachments: [{ text: text, color: "#f00" }] }
    end

    def response_for(text)
      { text: text, response_type: "in_channel" }
    end
  end
end

require_relative "./auth"
require_relative "./help"
require_relative "./releases"
