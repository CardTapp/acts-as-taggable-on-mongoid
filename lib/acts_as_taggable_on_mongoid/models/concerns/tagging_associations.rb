# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TaggingAssociations
        extend ActiveSupport::Concern

        included do
          ### ASSOCIATIONS:

          belongs_to :tag, counter_cache: true, inverse_of: :taggings
          belongs_to :tagger, polymorphic: true, optional: true

          # Tags and Taggings are created in an after_save event on taggable.
          # If autosave is not false, then this will cause the taggable object
          # to be saved AGAIN, that could cause a number of unwanted side-effects.
          belongs_to :taggable, polymorphic: true, autosave: false

          before_validation :atom_unset_blank_owner
        end

        private

        def atom_unset_blank_owner
          return if tagger_id.present? && tagger_type.present?

          unset(:tagger_id, :tagger_type)
        end
      end
    end
  end
end
