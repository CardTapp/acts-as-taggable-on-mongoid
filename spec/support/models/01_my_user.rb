# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class MyUser
  include Mongoid::Document
  include ActsAsTaggableOnMongoid::Tagger

  acts_as_tagger

  field :name, type: String
end
