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

    def recent_releases_for(attachments)
      {
        response_type: "in_channel",
        text: "Recent releases for #{application}",
        attachments: attachments
      }
    end

    def attachments_for(application)
      response = client.releases_for(application)
      response.map do |release|
        { text: "v#{release['version']} - #{release['description']} - " \
          "#{release['user']['email']} - #{release['created_at']}" }
      end
    end

    def response_for_release(release)
      {
        "attachments": [
          {
            "fallback": "Heroku release for #{application} - v#{release[:version]}",
            "text": "Release v#{release[:version]} of #{application}",
            "title": "https://#{application}.herokuapp.com",
            "title_link": "https://#{application}.herokuapp.com",
            "fields": [
              {
                "title": "By",
                "value": release[:user][:email],
                "short": true
              },
              {
                "title": "When",
                "value": release[:created_at],
                "short": true
              }
            ],
            "color": COLOR
          }
        ]
      }
    end

    def recent_releases
      Rails.logger.info "Fetching releases for #{application}"
      recent_releases_for(attachments_for(application))
    rescue StandardError
      response_for("Unable to fetch recent releases for #{application}.")
    end

    def version_from_args
      matches = command.command_text.match(/releases:\w+\s+([^\s]+)\s-a/)
      matches && matches[1]
    end

    def run
      @response = case subtask
                  when "info"
                    version = version_from_args
                    if version
                      response = client.release_info_for(application, version)
                      response_for_release(response)
                    else
                      response_for("release:info missing version, should be a number or uuid")
                    end
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
