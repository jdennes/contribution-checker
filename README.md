# ContributionChecker

Check whether a commit in a GitHub repository is counted as a [contribution][contributions] for a GitHub user.

_This project is currently a work in progress, and is not complete._

## Usage

```ruby
> ContributionChecker.check "username", "https://github.com/user/repo/commit/sha"
=> true
```

[contributions]: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile
