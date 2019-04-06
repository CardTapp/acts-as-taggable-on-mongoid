# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # This module includes the scopes needed/used by a Tagging model
      module TaggingScopes
        extend ActiveSupport::Concern

        DEFAULT_CONTEXT = "tags"

        included do
          # scope :owned_by, ->(owner) { where(tagger: owner) }
          # scope :not_owned, -> { where(tagger_id: nil, tagger_type: nil) }

          scope :by_contexts, ->(*contexts) { where(:context.in => Array.wrap(contexts.presence || DEFAULT_CONTEXT)) }
          scope :by_context, ->(context = DEFAULT_CONTEXT) { by_contexts(context.to_s) }
          scope :for_tag, ->(tag_definition) { where(taggable_type: tag_definition.owner.name).by_context(tag_definition.tag_type) }
        end
      end
    end
  end
end
