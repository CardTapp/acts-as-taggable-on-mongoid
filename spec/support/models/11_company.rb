# frozen_string_literal: true

# A test model used to show that a tag can have/use subclasses of the Tags table.
class Company
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String

  acts_as_taggable_on :locations
  acts_as_taggable_on :markets, tags_table: Market
end
