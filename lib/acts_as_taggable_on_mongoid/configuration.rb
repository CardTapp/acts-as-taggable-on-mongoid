# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  class Configuration
    attr_accessor :force_lowercase,
                  :force_parameterize,
                  :remove_unused_tags,
                  :default_parser,
                  :tags_counter,
                  :tags_table,
                  :taggings_table

    alias force_lowercase? force_lowercase
    alias force_parameterize? force_parameterize
    alias remove_unused_tags? remove_unused_tags
    alias tags_counter? tags_counter

    def initialize
      @force_lowercase    = false
      @force_parameterize = false
      @remove_unused_tags = false
      @tags_counter       = true
      @default_parser     = DefaultParser
      @tags_table         = ActsAsTaggableOnMongoid::Models::Tag
      @taggings_table     = ActsAsTaggableOnMongoid::Models::Tagging
    end
  end
end
