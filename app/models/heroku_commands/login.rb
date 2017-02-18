module HerokuCommands
  # Class for handling authenticating a user
  class Login < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      "login - Verify the user is authenticated with Heroku and GitHub."
    end

    def email
      user.heroku_user_information &&
        user.heroku_user_information["email"]
    end

    def run
      if user.onboarded?
        authenticated_user_response
      else
        user_onboarding_response
      end
    end

    def authenticated_user_response
      "You're authenticated as #{email} on Heroku."
    end

    def authenticate_github_response
      "You're not authenticated with GitHub yet.\n<#{command.github_auth_url}|Fix that>."
    end

    def authenticate_heroku_response
      "Please <#{command.flock_auth_url}|sign in to Heroku>."
    end

    def user_onboarding_response
      if user.heroku_configured?
        authenticate_github_response
      else
        authenticate_heroku_response
      end
    end
  end
end
