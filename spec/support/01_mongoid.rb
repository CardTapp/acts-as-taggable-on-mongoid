# frozen_string_literal: true

require "mongoid"

# config_file = YAML.safe_load(Rails.root.join("spec", "fixtures", "mongoid.yml"))
config_file = Pathname.new(__FILE__).join("..", "..", "fixtures", "mongoid.yml")

ENV["MONGOID_ENV"] = "test"

::Mongoid.load!(config_file)
