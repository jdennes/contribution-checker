require "octokit"

module ContributionChecker
  class Checker

    # Initialise a new Checker instance with an API access token and commit URL.
    #
    # @param options [Hash] Options which should take the form:
    # {
    #   :access_token => "<Your 40 char GitHub API token>",
    #   :commit_url   => "https://github.com/user/repo/commit/sha"
    # }
    # @return ContributionChecker::Checker
    def initialize(options = {})
      options.each do |key, val|
        instance_variable_set :"@#{key}", val
      end
      @client = Octokit::Client.new(:access_token => @access_token)
    end

    # Check whether the commit is counted as a contribution for the
    # authenticated user.
    #
    # @return Hash of the following form:
    # {
    #   :counted_as_contribution => true,
    #   :and_criteria => {
    #     :commit_in_valid_branch      => true,
    #     :commit_in_last_year         => true,
    #     :repo_not_a_fork             => true,
    #     :commit_email_linked_to_user => true,
    #   },
    #   :or_criteria => {
    #     :user_has_starred_repo                  => false,
    #     :user_can_push_to_repo_or_is_org_member => false,
    #     :user_has_fork_of_repo                  => true,
    #   }
    # }
    def check
      parts = URI.parse(@commit_url).path.split("/")
      @nwo = "#{parts[1]}/#{parts[2]}"
      @sha = parts[4]
      @user = @client.user
      @repo = @client.repository @nwo
      @commit = @client.commit @nwo, @sha

      @commit_in_valid_branch = commit_in_valid_branch?
      @commit_in_last_year = commit_in_last_year?
      @repo_not_a_fork = !repository_is_fork?
      @commit_email_linked_to_user = commit_email_linked_to_user?
      @user_has_starred_repo = user_has_starred_repo?
      @user_can_push_to_repo_or_is_org_member = user_can_push_to_repo_or_is_org_member?
      @user_has_fork_of_repo = user_has_fork_of_repo?

      {
        :contribution => and_criteria_met? && or_criteria_met?,
        :and_criteria => {
          :commit_in_valid_branch      => @commit_in_valid_branch,
          :commit_in_last_year         => @commit_in_last_year,
          :repo_not_a_fork             => @repo_not_a_fork,
          :commit_email_linked_to_user => @commit_email_linked_to_user,
        },
        :or_criteria => {
          :user_has_starred_repo                  => @user_has_starred_repo,
          :user_can_push_to_repo_or_is_org_member => @user_can_push_to_repo_or_is_org_member,
          :user_has_fork_of_repo                  => @user_has_fork_of_repo,
        }
      }
    end

    def commit_in_valid_branch?
      # If two refs are entirely different commit histories, the API responds
      # with a 404. Rescue Octokit::NotFound in this case.
      begin
        default_compare = @client.compare @repo[:full_name],
          @repo[:default_branch], @commit[:sha]
      rescue Octokit::NotFound
        default_compare = nil
      end

      # The compare status should be "identical" or "behind" if the commit is in
      # the default branch
      unless default_compare &&
        %w(identical behind).include?(default_compare[:status])

        # If the commit is not in the default branch, check the gh-pages branch
        begin
          gh_pages_compare = @client.compare @repo[:full_name], "gh-pages",
            @commit[:sha]
        rescue Octokit::NotFound
          gh_pages_compare = nil
        end
        return false if !gh_pages_compare
        return false if !%w(identical behind).include? gh_pages_compare [:status]
      end

      true
    end

    def commit_in_last_year?
      a_year_ago = Time.now - (365.25 * 86400)
      commit_time = @commit[:commit][:author][:date]
      (commit_time <=> a_year_ago) == 1
    end

    def repository_is_fork?
      @repo[:fork]
    end

    def commit_email_linked_to_user?
      true # TODO — Implement this.
    end

    def user_has_starred_repo?
      @client.starred?(@nwo)
    end

    def user_is_repo_org_member?
      false if @repo[:owner] == "User"
      @client.organization_member? @repo[:owner][:login], @user[:login]
    end

    def user_can_push_to_repo_or_is_org_member?
      @repo[:permissions][:push] || user_is_repo_org_member?
    end

    def user_has_fork_of_repo?
      true # TODO — Implement this.
    end

    def and_criteria_met?
      @commit_in_valid_branch && @commit_in_last_year &&
      @repo_not_a_fork && @commit_email_linked_to_user
    end

    def or_criteria_met?
      @user_has_starred_repo || @user_can_push_to_repo_or_is_org_member ||
      @user_has_fork_of_repo
    end
  end
end
