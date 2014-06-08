module ContributionChecker

  # Error class to help us rescue from invalid commit URL input.
  class InvalidCommitUrlError < StandardError
    def initialize
      super "Invalid commit URL provided"
    end
  end

end
