# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class AltTag < ActsAsTaggableOnMongoid::Models::Tag
  def self.collection_name
    'acts_as_taggable_on_mongoid_models_alt_tags'
  end

  ### ASSOCIATIONS:

  has_many :taggings, as: :tag, dependent: :destroy, class_name: "AltTagging"
end
