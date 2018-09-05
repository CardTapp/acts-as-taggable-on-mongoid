# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # This module adds methods for tracking tag definitions within Taggable classes
    module ListTags
      extend ActiveSupport::Concern

      class_methods do
        def tag_types
          @tag_types ||= {}.with_indifferent_access
        end

        # In order to allow dynamic tags, return a default tag_definition for any missing tag_type.
        # This means that any dynamic tag necessarily is created with the current defaults
        def tag_definition(tag_type)
          tag_types[tag_type] ||= ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type)
        end

        def define_tag(tag_type, options = {})
          tag_definition = tag_types[tag_type]

          return tag_definition if tag_definition

          tag_definition = tag_types[tag_type] = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(self, tag_type, options)

          tag_definition.define_base_relations
          tag_definition.define_relations
          tag_definition.add_tag_list
        end
      end
    end
  end
end
