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
  :contribution => true,
  :and_criteria => {
    :commit_in_valid_branch      => true,
    :commit_in_last_year         => true,
    :repo_not_a_fork             => true,
    :commit_email_linked_to_user => true,
    :commit_email                => "example@example.com",
    :default_branch              => "master"
  },
  :or_criteria => {
    :user_has_starred_repo   => false,
    :user_can_push_to_repo   => false,
    :user_is_repo_org_member => true,
    :user_has_fork_of_repo   => false
  }
}
```

You might also like to try out the [Contribution Checker][app] app built on top of this library:

![checker](https://cloud.githubusercontent.com/assets/65057/3352063/2a90d4b4-fa31-11e3-8733-c52d5df05bad.png)

Created by [@izuzak][izuzak] and [@jdennes][jdennes] at the [Hamburg Hackathon][hamburg-hackathon], June 2014.

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
[app]: http://contribution-checker.herokuapp.com/
[izuzak]: https://github.com/izuzak
[jdennes]: https://github.com/jdennes
[hamburg-hackathon]: http://hamburg-hackathon.de/hackathon/
