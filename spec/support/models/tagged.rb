# frozen_string_literal: true

# This is a basic class with Tags in it to be used to test tagging with.
class Tagged
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :string_field, type: String
end
