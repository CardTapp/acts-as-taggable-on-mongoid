# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class AltTag
  include ActsAsTaggableOnMongoid::Models::Concerns::TagModel

  ### ASSOCIATIONS:

  has_many :taggings, as: :tag, dependent: :destroy, class_name: "AltTagging"
end
