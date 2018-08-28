# frozen_string_literal: true

# A test model used to test ordered tags.
class OrderedTaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  acts_as_ordered_taggable
  acts_as_ordered_taggable_on :colours
end
