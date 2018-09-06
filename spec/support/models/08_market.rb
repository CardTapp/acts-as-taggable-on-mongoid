# frozen_string_literal: true

class Market < ActsAsTaggableOnMongoid::Models::Tag
  def self.collection_name
    "markets"
  end

  ### ASSOCIATIONS:

  has_many :taggings, dependent: :destroy, class_name: "Market"
end
