module HerokuCommands
  # Class for handling logout and identity information
  class Auth < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "auth:logout - Delete your user and all commands you've run.",
        "auth:whoami - Display the email of the authenticated user."
      ]
    end

    def run
      @response = case subtask
                  when "logout"
                    user.destroy
                    response_for("Successfuly removed your SlashHeroku user.")
                  when "whoami"
                    email = user.heroku_user_information &&
                            user.heroku_user_information["email"]

                    response_for("You're authenticated as #{email} on Heroku.")
                  else
                    help_for_task
                  end
    end
  end
end
