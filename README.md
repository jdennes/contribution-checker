# ContributionChecker

Check whether a commit in a GitHub repository is counted as a [contribution][contributions] for a GitHub user.

_This project is currently a work in progress, and is not complete._

## Usage

```ruby
> ContributionChecker.check "username", "https://github.com/user/repo/commit/sha"
=> {
  :counted_as_contribution => true,
  :and_criteria => {
    :commit_in_valid_branch       => true,
    :commit_in_last_year          => true,
    :repo_not_a_fork              => true,
    :commit_email_linked_to_user  => true, # Not possible to determine without authentication
  },
  :or_criteria => {
    :user_has_starred_repo        => false,
    :user_has_push_access_to_repo => false,
    :user_has_fork_of_repo        => true,
  }
}
```

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
