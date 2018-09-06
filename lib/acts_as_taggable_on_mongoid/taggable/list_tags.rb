# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # This module adds methods for tracking tag definitions within Taggable classes
    module ListTags
      extend ActiveSupport::Concern

      included do
        class_attribute :tag_types

        self.tag_types ||= {}.with_indifferent_access
      end

      class_methods do
        # In order to allow dynamic tags, return a default tag_definition for any missing tag_type.
        # This means that any dynamic tag necessarily is created with the current defaults
        def tag_definition(tag_type)
          return unless tag_type.present?

          tag_types[tag_type] ||= ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type)
        end

        def define_tag(tag_type, options = {})
          return if tag_type.blank?

          tag_definition = tag_types[tag_type]

          return tag_definition if tag_definition

          # tag_types is a class_attribute
          # As such, we have to replace it each time with a new array so that inherited classes and instances
          # are able to maintain separate lists if need be.
          self.tag_types = {}.with_indifferent_access.merge!(self.tag_types || {})
          tag_definition = self.tag_types[tag_type] = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type, options)

          tag_definition.define_base_relations
          tag_definition.define_relations
          tag_definition.add_tag_list
        end
      end
    end
  end
end
