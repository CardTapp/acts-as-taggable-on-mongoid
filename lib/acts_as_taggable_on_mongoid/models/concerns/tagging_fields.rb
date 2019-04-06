# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TaggingFields
        extend ActiveSupport::Concern

        included do
          include Mongoid::Document
          include Mongoid::Timestamps

          field :tag_name, type: String
          field :context, type: String

          # If/when adding the concept of a tagger, this index will need to be changed.
          index({ taggable_id: 1, taggable_type: 1, context: 1, tag_name: 1 }, unique: true, name: "tagging_taggable_context_tag_name")
          index(tag_name: 1)
          index(tag_id: 1, tag_type: 1)
        end
      end
    end
  end
end
