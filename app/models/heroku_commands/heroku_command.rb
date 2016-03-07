# Namespace for containing HerokuCommands
module HerokuCommands
  # Top-level class for implementing Heroku commands
  class HerokuCommand
    attr_reader :client, :description, :response
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
        text: "Available heroku #{task} commands:",
        attachments: self.class.help_documentation.map { |cmd| { text: cmd } }
      }
    end

    def response_for(text)
      { text: text, response_type: "in_channel" }
    end
  end
end

require_relative "./auth"
require_relative "./help"
require_relative "./releases"
