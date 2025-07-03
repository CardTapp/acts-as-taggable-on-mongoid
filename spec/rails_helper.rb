# frozen_string_literal: true

require "simplecov"
require "simplecov-rcov"

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
# SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

SimpleCov.start "rails" do
  add_filter "acts_as_taggable_on_mongoid/version"

  current_branch = `git rev-parse --abbrev-ref HEAD`.tr("\n", "")
  unless current_branch.match?(/master/)
    changed_files = `git diff --name-only #{current_branch} $(git merge-base #{current_branch} origin/master)`.split("\n")
    add_group "Changed" do |source_file|
      changed_files.detect do |filename|
        source_file.filename.end_with?(filename)
      end
    end
  end
end

require "logger"
require "active_support"
require "spec_helper"
require "mongoid"
require "timecop"
require "database_cleaner"
require "acts-as-taggable-on-mongoid"

ActsAsTaggableOnMongoid.eager_load!

Dir[Pathname.new(__FILE__).join("..", "support", "**", "*")].sort.each do |support_file|
  next if File.directory? support_file

  require support_file
end

require "cornucopia/rspec_hooks"
