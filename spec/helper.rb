require "rspec"
require "webmock/rspec"
require "contribution-checker"

WebMock.disable_net_connect!

def github_url(url)
  url =~ /^http/ ? url : "https://api.github.com#{url}"
end

def stub_get(url)
  stub_request(:get, github_url(url))
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

def json_response(file)
  {
    :body => fixture(file),
    :headers => {
      :content_type => 'application/json; charset=utf-8'
    }
  }
end
