# GitHub Contribution Checker

People :heart: GitHub Contributions. However, it's not always simple to tell why a commit isn't [counted as a contribution][contributions]. This library lets you check whether a specific commit qualifies as a contribution.

## Usage

```ruby
require "contribution-checker"

checker = ContributionChecker::Checker.new \
  :access_token => "<Your 40 char GitHub API token>",
  :commit_url   => "https://github.com/user/repo/commit/sha"

checker.check
=> {
  :counted_as_contribution => true,
  :and_criteria => {
    :commit_in_valid_branch      => true,
    :commit_in_last_year         => true,
    :repo_not_a_fork             => true,
    :commit_email_linked_to_user => true
  },
  :or_criteria => {
    :user_has_starred_repo   => false,
    :user_can_push_to_repo   => false,
    :user_is_repo_org_member => true,
    :user_has_fork_of_repo   => false
  }
}
```

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
