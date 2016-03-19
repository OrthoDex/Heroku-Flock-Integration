# Module for handling ChatOps patterns.
module ChatOpsPatterns
  extend ActiveSupport::Concern

  # Class for encapsulating a chat deployment request
  class Deployment
    attr_reader :application, :branch, :environment, :forced,
      :hosts, :second_factor
    def initialize(string)
      @string = string
      matches = deploy_pattern.match(string)
      if matches
        @forced        = matches[2] == "!"
        @application   = matches[3]
        @branch        = matches[4] || "master"
        @environment   = matches[5] || "staging"
        @hosts         = matches[6]
        @second_factor = matches[7]
      end
    end

    def deploy_pattern
      Regexp.new(pattern_parts.join(""))
    end

    def valid_slug
      "([-_\.0-9a-z]+)"
    end

    # rubocop:disable Metrics/LineLength
    def pattern_parts
      [
        "(deploy(?:\:[^\s]+)?)",                       # / prefix
        "(!)?\s+",                                     # Whether or not it was a forced deployment
        valid_slug.to_s,                               # application name, from apps.json
        "(?:\/([^\s]+))?",                             # Branch or sha to deploy
        "(?:\s+(?:to|in|on)\s+",                       # http://i.imgur.com/3KqMoRi.gif
        valid_slug.to_s,                               # Environment to release to
        "(?:\/([^\s]+))?)?\s*",                        # Host filter to try
        "(?:([cbdefghijklnrtuv]{32,64}|\d{6})?\s*)?$"  # Optional Yubikey
      ]
    end
    # rubocop:enable Metrics/LineLength
  end

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def chat_deployment_request(text)
    Deployment.new(text)
  end
end
