# frozen_string_literal: true

require "simplecov"
require "simplecov-rcov"

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
# SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

SimpleCov.start "rails" do
  add_filter "acts_as_taggable_on_mongoid/version"

  current_branch = `git rev-parse --abbrev-ref HEAD`.tr("\n", "")
  if current_branch !~ /master/
    changed_files = `git diff --name-only #{current_branch} $(git merge-base #{current_branch} origin/master)`.split("\n")
    add_group "Changed" do |source_file|
      changed_files.detect do |filename|
        source_file.filename.ends_with?(filename)
      end
    end
  end
end

require "spec_helper"
require "database_cleaner"

Dir[Pathname.new(__FILE__).join("..", "support", "**", "*")].sort.each do |support_file|
  next if File.directory? support_file

  require support_file
end

require "cornucopia/rspec_hooks"
