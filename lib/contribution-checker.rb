require "contribution-checker/version"
require "octokit"

module ContributionChecker

  def self.commit_in_valid_branch?(commit, repo)
    # If two refs are entirely different commit histories, the API responds with
    # a 404. Rescue Octokit::NotFound in this case.
    begin
      default_compare = Octokit.compare repo[:full_name],
        repo[:default_branch], commit[:sha]
    rescue Octokit::NotFound
      default_compare = nil
    end

    # The compare status should be "identical" or "behind" if the commit is in
    # the default branch
    unless default_compare and
      %w(identical behind).include? default_compare[:status]

      # If the commit is not in the default branch, check the gh-pages branch
      begin
        gh_pages_compare = Octokit.compare repo[:full_name], "gh-pages",
          commit[:sha]
      rescue Octokit::NotFound
        gh_pages_compare = nil
      end
      return false if !gh_pages_compare
      return false if !%w(identical behind).include? gh_pages_compare [:status]
    end

    true
  end

  def self.commit_authored_in_last_year?(commit)
    a_year_ago = Time.now - (365.25 * 86400)
    commit_time = commit[:commit][:author][:date]
    (commit_time <=> a_year_ago) == 1
  end

  def self.repository_is_fork?(repo)
    repo[:fork]
  end

  def self.commit_email_linked_to_user?(commit)
    true # Not possible to determine without authentication
  end

  def self.user_has_starred_repo?(user)
    true
  end

  def self.user_has_push_access_to_repo?
    true
  end

  def self.user_has_fork_of_repo?
    true
  end

  def self.and_criteria_met?(commit_in_valid_branch, commit_in_last_year,
    repo_not_a_fork, commit_email_linked_to_user)
    commit_in_valid_branch && commit_in_last_year && repo_not_a_fork &&
      commit_email_linked_to_user
  end

  def self.or_criteria_met?(user_has_starred_repo, user_has_push_access_to_repo,
    user_has_fork_of_repo)
    user_has_starred_repo || user_has_push_access_to_repo ||
      user_has_fork_of_repo
  end

  def self.check(username, url)
    parts = URI.parse(url).path.split("/")
    nwo = "#{parts[1]}/#{parts[2]}"
    sha = parts[4]
    user = Octokit.user username
    repo = Octokit.repository nwo
    commit = Octokit.commit nwo, sha

    commit_in_valid_branch = commit_in_valid_branch? commit, repo
    commit_in_last_year = commit_authored_in_last_year? commit
    repo_not_a_fork = !repository_is_fork?(repo)
    commit_email_linked_to_user = commit_email_linked_to_user? commit
    user_has_starred_repo = user_has_starred_repo? user
    user_has_push_access_to_repo = user_has_push_access_to_repo?
    user_has_fork_of_repo = user_has_fork_of_repo?

    {
      :contribution =>
        and_criteria_met?(
          commit_in_valid_branch,
          commit_in_last_year,
          repo_not_a_fork,
          commit_email_linked_to_user) &&
        or_criteria_met?(
          user_has_starred_repo,
          user_has_push_access_to_repo,
          user_has_fork_of_repo),
      :and_criteria => {
        :commit_in_valid_branch       => commit_in_valid_branch,
        :commit_in_last_year          => commit_in_last_year,
        :repo_not_a_fork              => repo_not_a_fork,
        :commit_email_linked_to_user  => commit_email_linked_to_user,
      },
      :or_criteria => {
        :user_has_starred_repo        => user_has_starred_repo,
        :user_has_push_access_to_repo => user_has_push_access_to_repo,
        :user_has_fork_of_repo        => user_has_fork_of_repo,
      }
    }

  end

end
