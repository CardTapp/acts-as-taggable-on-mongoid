# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # This module includes the scopes needed/used by a Tagging model
      module TaggingScopes
        extend ActiveSupport::Concern

        DEFAULT_CONTEXT = "tags"

        included do
          # aliased scopes from ActsAsTaggable
          scope :owned_by, ->(tagger) { tagged_by(tagger) }
          scope :not_owned, -> { tagged_by(nil) }

          scope :by_tag_types, ->(*tag_types) { where(:context.in => Array.wrap(tag_types.presence || DEFAULT_CONTEXT)) }
          scope :by_tag_type, ->(tag_type = DEFAULT_CONTEXT) { by_tag_types(tag_type.to_s) }
          scope :tagged_by, ->(tagger) { tagger ? where(tag_tagger: tagger) : where(:tag_tagger_id.exists => false) }
          scope :for_tag, ->(tag_definition) { where(taggable_type: tag_definition.owner.name).by_tag_type(tag_definition.tag_type) }
        end
      end
    end
  end
end
