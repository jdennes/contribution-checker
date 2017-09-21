# GitHub Contribution Checker

People :heart: GitHub Contributions. However, it's not always simple to tell why a commit isn't [counted as a contribution][contributions]. This library lets you check whether a specific commit qualifies as a contribution.

## Developing

To start working on the project:

```sh
script/bootstrap
```

To run the specs:

```sh
script/test
```

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
    :commit_email_is_not_generic => true,
    :commit_in_valid_branch      => true,
    :repo_not_a_fork             => true,
    :commit_email_linked_to_user => true,
    :commit_email                => "me@foo.com",
    :default_branch              => "master"
  },
  :or_criteria => {
    :user_has_starred_repo               => false,
    :user_can_push_to_repo               => false,
    :user_is_repo_org_member             => true,
    :user_has_fork_of_repo               => false,
    :user_has_opened_issue_or_pr_in_repo => false
  }
}
```

## App

You might like to try out the [Contribution Checker][app] app built on top of this library:

![checker](https://cloud.githubusercontent.com/assets/65057/6320756/b32c9328-bae6-11e4-9ba1-48ced9a5fb6e.png)

The source for the app is in [jdennes/contribution-checker-app][contribution-checker-app].

Created by [@izuzak][izuzak] and [@jdennes][jdennes] at the [Hamburg Hackathon][hamburg-hackathon], June 2014.

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
[app]: http://contribution-checker.herokuapp.com/
[contribution-checker-app]: https://github.com/jdennes/contribution-checker-app
[izuzak]: https://github.com/izuzak
[jdennes]: https://github.com/jdennes
[hamburg-hackathon]: http://hamburg-hackathon.de/hackathon/
