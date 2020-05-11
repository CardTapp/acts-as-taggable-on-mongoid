# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # Update and Destroy hooks for tags to update denormalized data.
      #
      # NOTE:  If the tag is cached AND owned, assumptions are made about the
      #        relationship of a Tag to the Taggings and the taggable_type.
      #
      #        Specifically, the taggable_type is assumed to have an ID field that
      #        matches the owner.  This field can be specified in the tag_definition
      #        as owner_id_field.
      #
      #        If there isn't a simple relationship like this then override the following
      #        methods to update the cached data properly:
      #         * remove_cached_taggings
      #         * update_cached_taggings
      module TagHooks
        extend ActiveSupport::Concern

        included do
          after_update :denormalize_tag_name
          after_destroy :remove_cached_taggings
        end

        private

        def denormalize_tag_name
          return unless name_changed?

          update_taggings
          update_cached_taggings
        end

        def update_taggings
          taggings.update_all(tag_name: name)
        end

        def remove_cached_taggings
          return if tag_definition.blank?
          return unless tag_definition.cached_in_model?

          cached_fields_query(name).update_all("$pull" => { "cached_#{tag_definition.tag_list_name}" => name })
        end

        def update_cached_taggings
          return if tag_definition.blank?
          return unless tag_definition.cached_in_model?

          cached_fields_query(name_was).update_all("$set" => { "cached_#{tag_definition.tag_list_name}.$" => name })
        end

        def cached_fields_query(chached_field_value)
          query = { "cached_#{tag_definition.tag_list_name}" => chached_field_value }

          if owner_id.present?
            id_field = tag_definition.owner_id_field || "#{owner_type.underscore}_id"

            query[id_field] = owner_id
          end

          taggable_type.constantize.unscoped.where(query)
        end
      end
    end
  end
end
