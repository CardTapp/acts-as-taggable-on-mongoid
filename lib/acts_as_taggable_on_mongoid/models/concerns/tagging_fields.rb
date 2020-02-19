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

          index({ taggable_id: 1, taggable_type: 1, context: 1, tagger_id: 1, tagger_type: 1, tag_name: 1 },
                unique: true,
                name:   "tagging_taggable_tagger_context_tag_name")
          index(tag_name: 1)
          index(tag_id: 1, tag_type: 1)
          index(tagger_id: 1, tagger_type: 1)
        end
      end
    end
  end
end
