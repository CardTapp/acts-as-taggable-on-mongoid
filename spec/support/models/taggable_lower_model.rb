# frozen_string_literal: true

# This is a basic class with Tags in it to be used to test tagging with.
class TaggableLowerModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  acts_as_taggable force_lowercase: true
  acts_as_taggable_on :languages, force_lowercase: true
  acts_as_taggable_on :skills, force_lowercase: true
  acts_as_taggable_on :needs, :offerings, force_lowercase: true

  has_many :untaggable_models

  attr_reader :tag_list_submethod_called

  def tag_list=(_value)
    @tag_list_submethod_called = true
    super
  end
end
