# frozen_string_literal: true

# A test model used to show that the Tag table can be subclassed and saved into a separate collection.
class Market
  include ActsAsTaggableOnMongoid::Models::Concerns::TagModel

  ### ASSOCIATIONS:

  has_many :taggings, dependent: :destroy, class_name: "ActsAsTaggableOnMongoid::Models::Tagging"
end
