# frozen_string_literal: true

# A model used for tests to test/show that models that do not use the acts_as_taggable methods do not include
# taggable methods.
class UntaggableModel
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String

  belongs_to :taggable_model
end
