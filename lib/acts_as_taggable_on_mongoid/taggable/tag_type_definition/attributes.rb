# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      module Attributes
        attr_reader :cached_in_model

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
          if defined?(preserve_tag_order)
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
      end
    end
  end
end
