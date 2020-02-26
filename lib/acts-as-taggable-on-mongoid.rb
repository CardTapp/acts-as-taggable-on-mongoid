# frozen_string_literal: true

require "acts_as_taggable_on_mongoid/version"

# The base module for the gem under which all classes are namespaced.
module ActsAsTaggableOnMongoid
  extend ::ActiveSupport::Autoload

  # rubocop:disable Metrics/BlockLength

  eager_autoload do
    autoload :Configuration
    autoload :TagList
    autoload :TaggerTagList
    autoload :GenericParser
    autoload :DefaultParser
    # autoload :TagsHelper

    autoload_under "taggable/tag_type_definition" do
      autoload :ListMethods
      autoload :Attributes
      autoload "Changeable"
      autoload :Names
    end

    autoload_under "taggable/utils" do
      autoload :TagListDiff
    end

    autoload_under "taggable/tagged_with_query" do
      autoload :Base
      autoload :AllTagsQuery
      autoload :AnyTagsQuery
      autoload :ExcludeTagsQuery
      autoload :MatchAllTagsQuery
    end

    autoload_under :Taggable do
      autoload :Cache
      #   autoload :Collection
      autoload :Core
      autoload :Changeable
      autoload :TagTypeDefinition
      autoload :ListTags
      autoload :TaggedWith
      autoload :TaggedWithQuery
      autoload :TaggerRelation
      #   autoload :Related
    end

    autoload_under :Tagger do
      autoload "TagMethods"
    end

    autoload :Taggable
    autoload :Tagger

    autoload_under "models/concerns" do
      autoload :TagFields
      autoload :TagAssociations
      autoload :TagValidations
      autoload :TagScopes
      autoload :TagMethods
      autoload :TagModel

      autoload :TaggingFields
      autoload :TaggingAssociations
      autoload :TaggingValidations
      autoload :TaggingScopes
      autoload :TaggingMethods
      autoload :TaggingModel
    end

    autoload_under :Models do
      autoload :Tag
      autoload :Tagging
    end

    autoload_under :Errors do
      autoload :DuplicateTagError
    end

    # autoload :Utils
    # autoload :Compatibility
  end

  # rubocop:enable Metrics/BlockLength

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end

  # :reek:ManualDispatch
  def self.method_missing(method_name, *args, &block)
    configuration.respond_to?(method_name) ? configuration.public_send(method_name, *args, &block) : super
  end

  # :reek:BooleanParameter
  # :reek:ManualDispatch
  def self.respond_to_missing?(method_name, _include_private = false)
    configuration.respond_to?(method_name) || super
  end
end

::ActiveSupport.on_load(:mongoid) do
  include ActsAsTaggableOnMongoid::Taggable
  include ActsAsTaggableOnMongoid::Tagger
end
