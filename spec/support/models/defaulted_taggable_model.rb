# frozen_string_literal: true

# This is a basic class with Tags in it to be used to test tagging with.
class DefaultedTaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  acts_as_taggable default: "Shazam, Black Adam"
  acts_as_taggable_on :languages, default: "Shazam, Black Adam"
  acts_as_taggable_on :skills, default: "Shazam, Black Adam"
  acts_as_taggable_on :needs, :offerings, default: "Shazam, Black Adam"

  has_many :untaggable_models

  attr_reader :tag_list_submethod_called

  def tag_list=(_value)
    @tag_list_submethod_called = true
    super
  end
end
