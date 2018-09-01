# frozen_string_literal: true

require "acts_as_taggable_on_mongoid/version"

# The base module for the gem under which all classes are namespaced.
module ActsAsTaggableOnMongoid
  extend ::ActiveSupport::Autoload

  eager_autoload do
    autoload :Configuration
    autoload :TagList
    autoload :GenericParser
    autoload :DefaultParser
    # autoload :Tagger
    # autoload :Tagging
    # autoload :TagsHelper
    # autoload :VERSION

    autoload_under :Taggable do
      #   autoload :Cache
      #   autoload :Collection
      autoload :Core
      autoload :TagTypeDefinition
      autoload :ListTags
      #   autoload :Dirty
      #   autoload :Ownership
      #   autoload :Related
    end

    autoload :Taggable

    autoload_under :Models do
      autoload :Tag
      autoload :Tagging
    end

    # autoload :Utils
    # autoload :Compatibility
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end

  def self.method_missing(method_name, *args, &block)
    configuration.respond_to?(method_name) ? configuration.send(method_name, *args, &block) : super
  end

  def self.respond_to_missing?(method_name, include_private = false)
    configuration.respond_to?(method_name) || super
  end
end

::ActiveSupport.on_load(:mongoid) do
  include ActsAsTaggableOnMongoid::Taggable
  # include ActsAsTaggableOn::Tagger
end
