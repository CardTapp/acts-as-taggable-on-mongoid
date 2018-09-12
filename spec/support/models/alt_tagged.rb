# frozen_string_literal: true

# This is a basic class with Tags which use non-default tag and tagging classes
class AltTagged
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :string_field, type: String
  field :name, type: String

  acts_as_taggable taggings_table: AltTagging,
                   tags_table:     AltTag
  acts_as_taggable_on :alt_tagging_other_tags,
                      taggings_table: AltTagging,
                      tags_table:     OtherAltTag
  acts_as_taggable_on :other_tagging_alt_tags,
                      taggings_table: OtherTagging,
                      tags_table:     OtherTag

  acts_as_ordered_taggable_on :other_tagging_other_tags,
                              :more_other_tagging_other_tags,
                              :another_other_tagging_other_tags,
                              taggings_table: OtherTagging,
                              tags_table:     OtherOtherTag
end
