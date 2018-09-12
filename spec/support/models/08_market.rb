# frozen_string_literal: true

# A test model used to show that the Tag table can be subclassed and saved into a separate collection.
class Market < ActsAsTaggableOnMongoid::Models::Tag
  def self.collection_name
    "markets"
  end

  ### ASSOCIATIONS:

  has_many :taggings, dependent: :destroy, class_name: "Market"
end
