# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing all tags that have ever been set on a model.
    class Tag
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      field :taggings_count, type: Integer
      field :context, type: String
      field :taggable_type, type: String

      # field :type, type: String

      index({ name: 1, taggable_type: 1, context: 1 }, unique: true)
    end
  end
end
