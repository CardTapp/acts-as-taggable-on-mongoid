# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      # This module extracts out the basic configuration type attributes of the tag definition.
      #
      # All attributes are based off of the Configuration class and in fact will default to
      # the corresponding value in the configuration if not explicitly specified/set when the
      # tag is defined.
      module Attributes
        attr_reader :cached_in_model,
                    :default

        def parser
          @parser || ActsAsTaggableOnMongoid.default_parser
        end

        def tags_table
          @tags_table || ActsAsTaggableOnMongoid.tags_table
        end

        def taggings_table
          @taggings_table || ActsAsTaggableOnMongoid.taggings_table
        end

        def force_lowercase
          if defined?(@force_lowercase)
            @force_lowercase
          else
            ActsAsTaggableOnMongoid.configuration.force_lowercase?
          end
        end

        def force_parameterize
          if defined?(@force_parameterize)
            @force_parameterize
          else
            ActsAsTaggableOnMongoid.configuration.force_parameterize?
          end
        end

        def preserve_tag_order
          if defined?(@preserve_tag_order)
            @preserve_tag_order
          else
            ActsAsTaggableOnMongoid.configuration.preserve_tag_order?
          end
        end

        def remove_unused_tags
          if defined?(@remove_unused_tags)
            @remove_unused_tags
          else
            ActsAsTaggableOnMongoid.configuration.remove_unused_tags?
          end
        end

        alias preserve_tag_order? preserve_tag_order
        alias cached_in_model? cached_in_model
        alias force_lowercase? force_lowercase
        alias force_parameterize? force_parameterize
        alias remove_unused_tags? remove_unused_tags

        private

        def default_value=(value)
          value           = Array.wrap(value)
          options         = value.extract_options!
          options[:parse] = true unless options.key?(:parse)

          @default = ActsAsTaggableOnMongoid::TagList.new self, value, options
        end
      end
    end
  end
end
