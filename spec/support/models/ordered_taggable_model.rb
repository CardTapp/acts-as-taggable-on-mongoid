# frozen_string_literal: true

class OrderedTaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  acts_as_ordered_taggable
  acts_as_ordered_taggable_on :colours
end
