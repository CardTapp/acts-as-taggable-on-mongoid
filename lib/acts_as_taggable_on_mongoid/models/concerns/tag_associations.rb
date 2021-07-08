# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagAssociations
        extend ActiveSupport::Concern

        included do
          ### ASSOCIATIONS:

          has_many :taggings, dependent: :destroy, class_name: "ActsAsTaggableOnMongoid::Models::Tagging", inverse_of: :tag
          belongs_to :owner, polymorphic: true, optional: true, index: true

          after_save :atom_unset_blank_owner
        end

        private

        def atom_unset_blank_owner
          return if !attributes.key?("owner_id") && !attributes.key?("owner_type")
          return if owner_id.present? && owner_type.present?

          unset(:owner_id, :owner_type)
        end
      end
    end
  end
end
