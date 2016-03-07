module HerokuCommands
  # Class for handling logout and identity information
  class Releases < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "releases -a APP - Display the last 10 releases for APP.",
        "releases:info RELEASE - View detailed information for a release.",
        "releases:rollback RELEASE - Roll back to an older release."
      ]
    end

    def recent_releases
      Rails.logger.info "Fetching releases for #{application}"
      response = client.recent_releases_for(application)
      Rails.logger.info response.to_json
      attachments = response.map do |release|
        { text: "v#{release['version']} - #{release['description']} - " \
                  "#{release['user']['email']} - #{release['created_at']}" }
      end
      {
        response_type: "in_channel",
        text: "Recent releases for #{application}",
        attachments: attachments
      }
    rescue StandardError
      response_for("Unable to fetch recent releases for #{application}.")
    end

    def run
      @response = case subtask
                  when "info"
                    response_for("release:info is currently unimplemented.")
                  when "rollback"
                    response_for("release:rollback is currently unimplemented.")
                  else
                    if application
                      recent_releases
                    else
                      help_for_task
                    end
                  end
    end
  end
end
