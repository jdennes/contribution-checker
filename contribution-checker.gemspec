# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "contribution-checker/version"

Gem::Specification.new do |spec|
  spec.name          = "contribution-checker"
  spec.version       = ContributionChecker::VERSION
  spec.authors       = ["James Dennes"]
  spec.email         = ["jdennes@gmail.com"]
  spec.summary       = %q{Check whether a commit is counted as a contribution.}
  spec.description   = %q{Check whether a GitHub commit is counted as a contribution for a specific GitHub user.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "octokit", "~> 3.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"

end
