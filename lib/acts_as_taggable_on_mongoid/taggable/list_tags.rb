# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # This module adds methods for tracking tag definitions within Taggable classes
    module ListTags
      extend ActiveSupport::Concern

      included do
        class_attribute :my_tag_types

        self.my_tag_types ||= {}.with_indifferent_access
      end

      def tag_types
        klass = self.class

        self.my_tag_types = klass.cleanup_tag_types(my_tag_types, klass)

        my_tag_types
      end

      def tag_definition(tag_type)
        return unless tag_type.present?

        tag_types[tag_type] ||= ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type)
      end

      class_methods do
        def tag_types
          self.my_tag_types = cleanup_tag_types(my_tag_types, self)

          my_tag_types
        end

        # :reek:UtilityFunction
        def cleanup_tag_types(tag_types, klass)
          return tag_types if tag_types.values.all? { |tag_definition| tag_definition.owner == klass }

          tag_types.each_with_object({}.with_indifferent_access) do |(key, tag_definition), hash|
            hash[key] = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.copy_from(klass, tag_definition)
          end
        end

        # In order to allow dynamic tags, return a default tag_definition for any missing tag_type.
        # This means that any dynamic tag necessarily is created with the current defaults
        def define_tag(tag_type, options = {})
          return if tag_type.blank?

          tag_definition = tag_types[tag_type]

          return tag_definition if tag_definition

          # tag_types is a class_attribute
          # As such, we have to replace it each time with a new array so that inherited classes and instances
          # are able to maintain separate lists if need be.
          new_tag_types     = {}.with_indifferent_access.merge!(tag_types || {})
          self.my_tag_types = new_tag_types
          tag_definition    = new_tag_types[tag_type] = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type, options)

          tag_definition.define_base_relations
          tag_definition.define_relations
          tag_definition.add_tag_list
        end
      end
    end
  end
end
