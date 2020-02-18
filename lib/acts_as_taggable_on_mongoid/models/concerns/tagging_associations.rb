# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TaggingAssociations
        extend ActiveSupport::Concern

        included do
          ### ASSOCIATIONS:

          belongs_to :tag, counter_cache: true, inverse_of: :taggings
          belongs_to :tag_tagger, polymorphic: true, optional: true
          belongs_to :taggable, polymorphic: true

          before_validation :atom_unset_blank_owner
        end

        private

        def atom_unset_blank_owner
          return if tag_tagger_id.present? && tag_tagger_type.present?

          unset(:tag_tagger_id, :tag_tagger_type)
        end
      end
    end
  end
end
