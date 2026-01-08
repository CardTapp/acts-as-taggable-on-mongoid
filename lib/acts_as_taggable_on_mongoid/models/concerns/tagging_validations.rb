# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # This module includes the validations needed/used by a Tagging model
      module TaggingValidations
        extend ActiveSupport::Concern

        included do
          validates :tag_name, presence: true
          validates :context, presence: true

          validates :tag_name, uniqueness: { scope: %i[taggable_id taggable_type context tagger_id tagger_type], message: "is already taken" }
          validates :tag_id, uniqueness: { scope: %i[taggable_id taggable_type context tagger_id tagger_type], message: "is already taken" }
        end
      end
    end
  end
end
