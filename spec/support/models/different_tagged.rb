# frozen_string_literal: true

# This is a basic class with Tags which use non-default tag and tagging classes
class DifferentTagged
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String

  acts_as_taggable taggings_table: AltTagging,
                   tags_table:     AltTag

  acts_as_taggable_on :custom_parsers, parser: ActsAsTaggableOnMongoid::GenericParser
  acts_as_taggable_on :orders, preserve_tag_order: true
  acts_as_taggable_on :cases, force_lowercase: true
  acts_as_taggable_on :params, force_parameterize: true
  acts_as_taggable_on :unuseds, remove_unused_tags: true
  acts_as_taggable_on :defaults, default: "a, b"
end
