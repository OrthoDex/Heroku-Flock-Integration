module SlashHeroku
  module Support
    module Helpers
      module Api
        def default_headers(token, version = 3)
          {
            "Accept" => "application/vnd.heroku+json; version=#{version}",
            "Accept-Encoding" => "",
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json",
            "User-Agent" => "Faraday v0.9.2"
          }
        end
      end
    end
  end
end
