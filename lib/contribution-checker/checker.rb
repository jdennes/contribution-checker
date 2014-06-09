require "octokit"

# Check whether a GitHub commit is counted as a contribution for a specific
# GitHub user.
#
# @see https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
module ContributionChecker

  # The Checker.
  class Checker

    # Initialise a new Checker instance with an API access token and commit URL.
    #
    # @param options [Hash] Options which should take the form:
    # {
    #   :access_token => "<Your 40 char GitHub API token>",
    #   :commit_url   => "https://github.com/user/repo/commit/sha"
    # }
    #
    # @return [ContributionChecker::Checker] Contribution checker initialised
    # for an authenticated user and a specific commit
    def initialize(options = {})
      options.each do |key, val|
        instance_variable_set :"@#{key}", val
      end
      @client = Octokit::Client.new(:access_token => @access_token)
    end

    # Checks whether the commit is counted as a contribution for the
    # authenticated user.
    #
    # @return [Hash] The return value takes the following form:
    # {
    #   :contribution => true,
    #   :and_criteria => {
    #     :commit_in_valid_branch      => true,
    #     :commit_in_last_year         => true,
    #     :repo_not_a_fork             => true,
    #     :commit_email_linked_to_user => true
    #   },
    #   :or_criteria => {
    #     :user_has_starred_repo   => false,
    #     :user_can_push_to_repo   => false,
    #     :user_is_repo_org_member => true,
    #     :user_has_fork_of_repo   => false
    #   }
    # }
    def check
      @nwo, @sha = parse_commit_url @commit_url
      begin
        @commit = @client.commit @nwo, @sha
      rescue Octokit::NotFound
        raise ContributionChecker::InvalidCommitUrlError
      rescue Octokit::Unauthorized
        raise ContributionChecker::InvalidAccessTokenError
      end
      @repo = @client.repository @nwo
      @user = @client.user

      @commit_in_valid_branch = commit_in_valid_branch?
      @commit_in_last_year = commit_in_last_year?
      @repo_not_a_fork = !repository_is_fork?
      @commit_email_linked_to_user = commit_email_linked_to_user?
      @user_has_starred_repo = user_has_starred_repo?
      @user_can_push_to_repo = user_can_push_to_repo?
      @user_is_repo_org_member = user_is_repo_org_member?
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
          :user_has_starred_repo   => @user_has_starred_repo,
          :user_can_push_to_repo   => @user_can_push_to_repo,
          :user_is_repo_org_member => @user_is_repo_org_member,
          :user_has_fork_of_repo   => @user_has_fork_of_repo,
        }
      }
    end

  private

    # Parses the commit URL provided.
    #
    # @return [Array] URL parts: nwo, sha
    def parse_commit_url(url)
      begin
        parts = URI.parse(@commit_url).path.split("/")
        nwo = "#{parts[1]}/#{parts[2]}"
        sha = parts[4]
        return nwo, sha
      rescue
        raise ContributionChecker::InvalidCommitUrlError
      end
    end

    # Checks whether the commit is in a valid branch. A valid branch is defined
    # as either the default branch of the repository, or the gh-pages branch.
    #
    # @return [Boolean]
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
      if default_compare.nil? ||
        !(%w(identical behind).include?(default_compare[:status]))

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

    # Checks whether the commit was authored in the last year.
    #
    # @return [Boolean]
    def commit_in_last_year?
      a_year_ago = Time.now - (365.25 * 86400)
      commit_time = @commit[:commit][:author][:date]
      (commit_time <=> a_year_ago) == 1
    end

    # Checks whether the repository is a fork.
    #
    # @return [Boolean]
    def repository_is_fork?
      @repo[:fork]
    end

    # Checks whether the commit email is linked to the authenticated user's
    # GitHub account.
    #
    # @return [Boolean]
    def commit_email_linked_to_user?
      @emails = @client.emails
      @emails.map { |e| e[:email] }.include? @commit[:commit][:author][:email]
    end

    # Checks whether the authenticated user has starred the repository in which
    # the commit exists.
    #
    # @return [Boolean]
    def user_has_starred_repo?
      @client.starred?(@nwo)
    end

    # Checks whether the authenticated user is a member of the organization
    # that owns the repository (if the repository is owned by an organization
    # account).
    #
    # @return [Boolean]
    def user_is_repo_org_member?
      return false if @repo[:owner] != "Organization"
      @client.organization_member? @repo[:owner][:login], @user[:login]
    end

    # Checks whether the authenticated user has push access to the repository in
    # which the commit exists.
    #
    # @return [Boolean]
    def user_can_push_to_repo?
      @repo[:permissions][:push]
    end

    # Checks whether the authenticated user has forked the repository in which
    # the commit exists.
    #
    # @return [Boolean]
    def user_has_fork_of_repo?
      # The API doesn't provide a simple means of checking whether a user has
      # forked a repository.

      # First, if there are no forks for the repository, return false.
      return false if @repo[:forks_count] == 0

      # Then check whether it's worth getting the list of forks
      if @repo[:forks_count] <= 100
        repo_forks = @client.forks @repo[:full_name], :per_page => 100
        repo_forks.each do |f|
          return true if f[:owner][:login] == @user[:login]
        end
      end

      # Then try to directly find a repository with the same name as the
      # repository in which the commit exists.
      potential_fork_nwo = "#{@user[:login]}/#{@repo[:name]}"
      begin
        potential_fork = @client.repository potential_fork_nwo
        return true if potential_fork[:parent][:full_name] == @repo[:full_name]
      rescue Octokit::NotFound
        # Keep going...
      end

      # Otherwise, get the user's forks and check the `parent` field of each
      # fork to see whether it matches @repo.
      @client.auto_paginate = true
      @user_repos = @client.repos
      @user_forks = @user_repos.select { |r| r[:fork] }
      @user_forks.each do |f|
        r = @client.repository f[:full_name]
        return true if r[:parent][:full_name] == @repo[:full_name]
      end
      false
    end

    # Checks whether the "and" criteria for counting a commit as a contribution
    # are correctly met.
    #
    # @return [Boolean]
    def and_criteria_met?
      @commit_in_valid_branch &&
      @commit_in_last_year &&
      @repo_not_a_fork &&
      @commit_email_linked_to_user
    end

    # Checks whether the "or" criteria for counting a commit as a contribution
    # are correctly met.
    #
    # @return [Boolean]
    def or_criteria_met?
      @user_has_starred_repo ||
      @user_can_push_to_repo ||
      @user_is_repo_org_member ||
      @user_has_fork_of_repo
    end
  end
end
