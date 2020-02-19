# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class AltMyUser
  include Mongoid::Document
  include ActsAsTaggableOnMongoid::Tagger

  acts_as_tagger taggings_table: AltTagging, tags_table: AltTag

  field :name, type: String
end
