# Module for handling ChatOps patterns.
module ChatOpsPatterns
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def valid_slug_pattern
    "([-_\.0-9a-z]+)"
  end

  def deploy_pattern
    Regexp.new(deploy_pattern_parts.join(""))
  end

  # rubocop:disable Metrics/LineLength
  def deploy_pattern_parts
    [
      "(deploy(?:\:[^\s]+)?)",                       # / prefix
      "(!)?\s+",                                     # Whether or not it was a forced deployment
      valid_slug_pattern.to_s,                       # application name, from apps.json
      "(?:\/([^\s]+))?",                             # Branch or sha to deploy
      "(?:\s+(?:to|in|on)\s+",                       # http://i.imgur.com/3KqMoRi.gif
      valid_slug_pattern.to_s,                       # Environment to release to
      "(?:\/([^\s]+))?)?\s*",                        # Host filter to try
      "(?:([cbdefghijklnrtuv]{32,64}|\d{6})?\s*)?$"  # Optional Yubikey
    ]
  end
end
