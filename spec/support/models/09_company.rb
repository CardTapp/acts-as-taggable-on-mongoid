# frozen_string_literal: true

class Company
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :name, type: String

  acts_as_taggable_on :locations
  acts_as_taggable_on :markets, tags_table: Market
end
