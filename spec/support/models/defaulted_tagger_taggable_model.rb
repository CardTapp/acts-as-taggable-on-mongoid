# frozen_string_literal: true

# This is a basic class with Tags in it to be used to test tagging with.
class DefaultedTaggerTaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  belongs_to :my_user

  acts_as_taggable default: "Shazam, Black Adam", tagger: true
  acts_as_taggable_on :languages, default: "Shazam, Black Adam", tagger: { tag_list_uses_default_tagger: true, default_tagger: :language_user }
  acts_as_taggable_on :skills, default: "Shazam, Black Adam", tagger: { default_tagger: :my_user }
  acts_as_taggable_on :needs, :offerings, default: "Shazam, Black Adam", tagger: { tag_list_uses_default_tagger: true, default_tagger: :my_user }
  acts_as_taggable_on :preserved,
                      default:            "Shazam, Black Adam",
                      preserve_tag_order: true,
                      tagger:             { tag_list_uses_default_tagger: true, default_tagger: :my_user }
  acts_as_taggable_on :default_with_tagger,
                      default: ["Shazam, Black Adam", tagger: :default_tagger],
                      tagger:  { tag_list_uses_default_tagger: true, default_tagger: :my_user }

  has_many :untaggable_models

  attr_reader :tag_list_submethod_called

  # :reek:UtilityFunction
  def language_user
    MyUser.find_or_create_by! name: "Language User"
  end

  # :reek:UtilityFunction
  def default_tagger
    MyUser.find_or_create_by! name: "Default Tagger"
  end

  def tag_list=(_value)
    @tag_list_submethod_called = true
    super
  end
end
