require "octokit"

module ContributionChecker

  def self.in_default_or_gh_pages(commit, repo)
    # repo.default_branch
    true
  end

  def self.check(user, url)
    sha = URI.parse(url).path.split("/")[4]
    @repo    = Octokit::Repository.from_url url
    @commit  = Octokit.commit @repo, sha

    return unless in_default_or_gh_pages @commit, @repo

    true
  end
end
