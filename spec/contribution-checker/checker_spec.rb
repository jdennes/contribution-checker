require "helper"

describe ContributionChecker::Checker do

  describe "#check" do

    context "when an invalid URL is provided as a commit URL" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "your token",
        :commit_url   => "not a url"
      }

      it "raises an error" do
        expect { checker.check }.to raise_error ContributionChecker::InvalidCommitUrlError
      end
    end

    context "when a valid URL is provided which isn't a commit URL" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "your token",
        :commit_url   => "https://example.com/"
      }

      before do
        stub_request(:get, "https://api.github.com/repos/commits/").to_return(
         :status  => 404, :body => "")
      end

      it "raises an error" do
        expect { checker.check }.to raise_error ContributionChecker::InvalidCommitUrlError
      end
    end

    context "when an invalid access token is provided" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "invalid access token",
        :commit_url   => "https://github.com/git/git-scm.com/commit/f6b5cb6"
      }

      before do
        stub_request(:get, "https://api.github.com/repos/git/git-scm.com/commits/f6b5cb6").to_return(
         :status  => 401, :body => "")
      end

      it "raises an error" do
        expect { checker.check }.to raise_error ContributionChecker::InvalidAccessTokenError
      end
    end

    context "when a commit is in the default branch and is successfully checked" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("repo.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end

    context "when a commit is completely seperate to the default branch but is in gh-pages" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("repo.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker/compare/gh-pages...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("gh-pages_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end

    context "when a commit is ahead of the default branch but is in gh-pages" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("repo.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare_ahead.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/gh-pages...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("gh-pages_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end

    context "when a commit is not in the default branch and not in gh-pages" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("repo.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker/compare/gh-pages...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(:status => 404)
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(false)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(false)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end


    context "when a commit is in the default branch and the user is a member of the org owning the repository" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("org_owned_repo.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
        stub_get("/orgs/github/members/jdennes").
          to_return(:status => 204)
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(true)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end

    context "when a commit is in the default branch and the user has a fork of the repository" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/jdennes/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/jdennes/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("repo_with_forks.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/jdennes/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/jdennes/contribution-checker").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker/forks?per_page=100").
          to_return(json_response("repo_forks.json"))
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(true)
      end
    end

    context "when a commit is in the default branch and there are too many forks of the repository to check them all" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/someone/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/someone/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/someone/contribution-checker").
          to_return(json_response("repo_with_too_many_forks.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/someone/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/someone/contribution-checker").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker").
          to_return(json_response("potential_fork.json"))
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(true)
      end
    end

    context "when a commit is in the default branch and the user's forks are checked" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/someone/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/someone/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/someone/contribution-checker").
          to_return(json_response("repo_with_too_many_forks.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/someone/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/someone/contribution-checker").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker").
          to_return(:status => 404)
        stub_get("/user/repos?per_page=100").
          to_return(json_response("user_repos.json"))
        stub_get("/repos/jdennes/myfork").
          to_return(json_response("user_fork.json"))
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(true)
      end
    end

    context "when a commit is in the default branch and the user's forks are checked and fails" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "token",
        :commit_url   => "https://github.com/someone/contribution-checker/commit/731e83d4abf1bd67ac6ab68d18387693482e47cf"
      }

      before do
        stub_get("/repos/someone/contribution-checker/commits/731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("commit.json"))
        stub_get("/repos/someone/contribution-checker").
          to_return(json_response("repo_with_too_many_forks.json"))
        stub_get("/user").
          to_return(json_response("user.json"))
        stub_get("/repos/someone/contribution-checker/compare/master...731e83d4abf1bd67ac6ab68d18387693482e47cf").
          to_return(json_response("default_compare.json"))
        stub_get("/user/emails").
          to_return(json_response("emails.json"))
        stub_get("/user/starred/someone/contribution-checker").
          to_return(:status => 404)
        stub_get("/repos/jdennes/contribution-checker").
          to_return(:status => 404)
        stub_get("/user/repos?per_page=100").
          to_return(json_response("user_repos.json"))
        stub_get("/repos/jdennes/myfork").
          to_return(json_response("user_fork_not_matching.json"))
      end

      it "returns the check result" do
        result = checker.check
        expect(result).to be_a(Hash)

        expect(result[:contribution]).to eq(true)

        expect(result[:and_criteria][:commit_in_valid_branch]).to eq(true)
        expect(result[:and_criteria][:commit_in_last_year]).to eq(true)
        expect(result[:and_criteria][:repo_not_a_fork]).to eq(true)
        expect(result[:and_criteria][:commit_email_linked_to_user]).to eq(true)

        expect(result[:or_criteria][:user_has_starred_repo]).to eq(false)
        expect(result[:or_criteria][:user_can_push_to_repo]).to eq(true)
        expect(result[:or_criteria][:user_is_repo_org_member]).to eq(false)
        expect(result[:or_criteria][:user_has_fork_of_repo]).to eq(false)
      end
    end

  end

end
