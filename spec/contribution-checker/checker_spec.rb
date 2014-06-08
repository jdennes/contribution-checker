require 'helper'

describe ContributionChecker::Checker do

  describe '#check' do

    context "when an invalid URL is provided as a commit URL" do
      let(:checker) { checker = ContributionChecker::Checker.new \
        :access_token => "<Your 40 char GitHub API token>",
        :commit_url   => "not a url"
      }

      it "raises an error" do
        expect { checker.check }.to raise_error ContributionChecker::InvalidCommitUrlError
      end
    end

  end

end
