# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  # A configuration class for the ActsAsTaggableOnMongoid gem.
  #
  # These global configurations are default configuration settings for the gem and will drive individual
  # tag definitions if the tag does not specify a different value when the tag is defined/added to a model.
  #
  # The configuration options are:
  #   * force_lowercase     - If set, values stored into the tags and taggings table will be downcased before being saved.
  #                           this allows for case-insensitive comparisons of values in the database.
  #
  #                           Because Mongo does not support methods on database calls like SQL does, the strict_case_match
  #                           option from ActsAsTaggableOn is not supported.  All comparisons are done case sensitive.
  #   * force_parameterize  - If set, values stored into the tags and taggings table will be parameterized before being saved.
  #   * remove_unused_tags  - If set when a Tagging is destroyed, the correlated Tag will also be destroyed if there are no
  #                           other Taggings associated with that Tag.
  #   * default_parser      - The parser class to be used to convert strings to arrays of values and to convert arrays of
  #                           values back to strings.  See GenericParser for details on creating your own parser.
  #   * tags_table          - The model class to be used to store Tag objects.
  #                           Custom classes can be used if you wish to store Tags in different tables for some tags if desired,
  #                           but it is expected that the Tags table will have equivalent fields, scopes and methods as the
  #                           ActsAsTaggableOn::Models::Tag class.  In most cases, you can derive from the Tag class and simply
  #                           override the relations or methods to achieve any differences you want/need.
  #   * taggings_table      - The model class to be used to store Tagging objects.
  #                           Custom classes can be used if you wish to store Taggings in different tables for some tags if desired,
  #                           but it is expected that the Taggings table will have equivalent fields, scopes and methods as the
  #                           ActsAsTaggableOn::Models::Tagging class.  In most cases, you can derive from the Tagging class and simply
  #                           override the relations or methods to achieve any differences you want/need.
  #
  # Unsupported configurations:
  #   * strict_case_match - This is not supported.  Use the `forc_lowercase` option to achieve case insensitive data storage and
  #                         comparisons.
  #   * tags_counter      - This is defined in the Tags and Taggings models, and is not configured through the configuration
  #                         nor tag defnitions.
  #
  #                         See spec tests for examples in creating your own Tag or Tagging models to customize this behavior.
  class Configuration
    # :reek:Attribute
    # :reek:TooManyInstanceVariables
    attr_accessor :force_lowercase,
                  :force_parameterize,
                  :remove_unused_tags,
                  :default_parser,
                  :tags_table,
                  :taggings_table,
                  :preserve_tag_order

    # For duck compatibility with ActsAsTaggableOn.  Do not use.
    def tags_counter
      Rails.logger.warn "This feature is not supported."
    end

    def strict_case_match
      Rails.logger.warn "This feature is not supported."
    end

    alias force_lowercase? force_lowercase
    alias force_parameterize? force_parameterize
    alias preserve_tag_order? preserve_tag_order
    alias remove_unused_tags? remove_unused_tags
    alias strict_case_match? strict_case_match
    alias tags_counter? tags_counter

    def initialize
      @force_lowercase    = false
      @force_parameterize = false
      @preserve_tag_order = false
      @remove_unused_tags = false
      @tags_counter       = true
      @default_parser     = DefaultParser
      @tags_table         = ActsAsTaggableOnMongoid::Models::Tag
      @taggings_table     = ActsAsTaggableOnMongoid::Models::Tagging
    end
  end
end
