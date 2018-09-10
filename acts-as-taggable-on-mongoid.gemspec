# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "acts_as_taggable_on_mongoid/version"

Gem::Specification.new do |spec|
  spec.name    = "acts-as-taggable-on-mongoid"
  spec.version = ActsAsTaggableOnMongoid::VERSION
  spec.authors = ["RealNobody"]
  spec.email   = ["admin@cardtapp.com"]

  spec.summary     = "A partial mongoid implementation of tagging based on/inspired by acts-as-taggable-on."
  spec.description = "A partial mongoid implementation of tagging based on/inspired by acts-as-taggable-on."
  spec.homepage    = "http://www.cardtapp.com"
  spec.license     = "MIT"

  # # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "http://RubyGems.org"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "mongoid", "~> 5.2"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "codecov", "~> 0.1", "~> 0.1.0"
  spec.add_development_dependency "cornucopia"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "pronto"
  spec.add_development_dependency "pronto-circleci"
  spec.add_development_dependency "pronto-brakeman"
  spec.add_development_dependency "pronto-fasterer"
  spec.add_development_dependency "pronto-rails_best_practices"
  spec.add_development_dependency "pronto-reek"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
end
