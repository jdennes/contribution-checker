require "contribution-checker/version"
require "octokit"

module ContributionChecker

  def self.in_default_or_gh_pages(commit, repo)
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
      %w[identical behind].include? default_compare[:status]

      # If the commit is not in the default branch, check the gh-pages branch
      begin
        gh_pages_compare = Octokit.compare repo[:full_name], "gh-pages", commit[:sha]
      rescue Octokit::NotFound
        gh_pages_compare = nil
      end
      return false if !gh_pages_compare
      return false if !%w[identical behind].include? gh_pages_compare [:status]
    end

    true
  end

  def self.authored_in_last_year(commit)
    a_year_ago = Time.now - (365.25 * 86400)
    commit_time = commit[:commit][:author][:date]
    (commit_time <=> a_year_ago) == 1
  end

  def self.check(user, url)
    parts = URI.parse(url).path.split("/")
    nwo = "#{parts[1]}/#{parts[2]}"
    sha = parts[4]
    @repo    = Octokit.repository nwo
    @commit  = Octokit.commit nwo, sha

    return false unless in_default_or_gh_pages @commit, @repo
    return false unless authored_in_last_year @commit

    true
  end

end
