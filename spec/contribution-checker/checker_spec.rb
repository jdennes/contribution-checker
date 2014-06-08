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
         :status  => 404, :body    => "")
      end

      it "raises an error" do
        expect { checker.check }.to raise_error ContributionChecker::InvalidCommitUrlError
      end
    end

  end

end
