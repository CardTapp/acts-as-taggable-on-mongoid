# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagAssociations
        extend ActiveSupport::Concern

        included do
          ### ASSOCIATIONS:

          has_many :taggings, dependent: :destroy, class_name: "ActsAsTaggableOnMongoid::Models::Tagging"
          belongs_to :tagger, polymorphic: true, optional: true, index: true

          after_save :atom_unset_blank_tagger
        end

        private

        def atom_unset_blank_tagger
          return if !attributes.key?("tagger_id") && !attributes.key?("tagger_type")
          return if tagger_id.present? && tagger_type.present?

          unset(:tagger_id, :tagger_type)
        end
      end
    end
  end
end
