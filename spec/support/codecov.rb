if ENV["CI"] == "true"
  require "simplecov"
  SimpleCov.filters.clear
  SimpleCov.start do |_file|
    add_filter do |file|
      !file.filename.start_with?("lib/") && !file.filename.start_with?("bin/")
    end
  end
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end