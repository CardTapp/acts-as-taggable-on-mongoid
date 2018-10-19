module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # This module includes the methods and callbacks needed/used by a Tagging model
      module TaggingMethods
        extend ActiveSupport::Concern

        included do
          after_save :tagging_saved
          after_destroy :tagging_destroyed
          after_destroy :remove_unused_tags
        end

        ### INSTANCE METHODS:

        private

        def remove_unused_tags
          return nil unless taggable

          tag_definition = taggable.tag_types[context]

          return unless tag_definition&.remove_unused_tags?

          tag.destroy if tag.reload.taggings_count.zero?
        end

        def tagging_saved
          tag_definition = taggable.tag_types[context]

          return unless tag_definition

          tag_list = taggable.public_send(tag_definition.tag_list_name)
          tag_list.add_tagging(self)
        end

        def tagging_destroyed
          taggable_was = taggable_type_was.constantize.where(id: taggable_id_was).first

          return unless taggable_was

          tag_definition = taggable_was.tag_types[context_was]

          return unless tag_definition

          taggable_was.public_send(tag_definition.tag_list_name).remove(tag_name_was)
        end
      end
    end
  end
end
