# ContributionChecker

People :heart: GitHub Contributions. This library lets you check whether one of your commits qualifies as a [contribution][contributions].

## Usage

```ruby
checker = ContributionChecker::Checker.new \
  :access_token => "<Your 40 char GitHub API token>",
  :commit_url   => "https://github.com/user/repo/commit/sha"
)

checker.check
=> {
  :counted_as_contribution => true,
  :and_criteria => {
    :commit_in_valid_branch      => true,
    :commit_in_last_year         => true,
    :repo_not_a_fork             => true,
    :commit_email_linked_to_user => true,
  },
  :or_criteria => {
    :user_has_starred_repo                  => false,
    :user_can_push_to_repo_or_is_org_member => false,
    :user_has_fork_of_repo                  => true,
  }
}
```

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
