# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class OtherTag
  include ActsAsTaggableOnMongoid::Models::Concerns::TagModel

  has_many :taggings, as: :tag, dependent: :destroy, class_name: "OtherTagging"
end
