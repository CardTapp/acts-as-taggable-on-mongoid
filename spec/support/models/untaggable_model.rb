# frozen_string_literal: true

class UntaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String

  belongs_to :taggable_model
end
