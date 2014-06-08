module ContributionChecker

  # Error class to help us rescue from invalid commit URL input.
  class InvalidCommitUrlError < StandardError
    def initialize
      super "Invalid commit URL provided"
    end
  end

  # Error class to help us rescue from invalid access token input.
  class InvalidAccessTokenError < StandardError
    def initialize
      super "Invalid access token provided"
    end
  end

end
