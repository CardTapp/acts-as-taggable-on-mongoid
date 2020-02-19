# frozen_string_literal: true

# This is a basic class with Tags in it to be used to test tagging with.
class TaggerTaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  belongs_to :my_user

  acts_as_taggable tagger: true
  acts_as_taggable_on :languages, tagger: { tag_list_uses_default_tagger: true, default_tagger: :language_user }
  acts_as_taggable_on :skills, tagger: { default_tagger: :my_user }
  acts_as_taggable_on :needs, :offerings, tagger: { tag_list_uses_default_tagger: true, default_tagger: :my_user }
  acts_as_taggable_on :preserved, preserve_tag_order: true, tagger: { tag_list_uses_default_tagger: true, default_tagger: :my_user }

  attr_reader :tag_list_submethod_called

  # :reek:UtilityFunction
  def language_user
    MyUser.find_or_create_by! name: "Language User"
  end

  def tag_list=(_value)
    @tag_list_submethod_called = true
    super
  end
end
