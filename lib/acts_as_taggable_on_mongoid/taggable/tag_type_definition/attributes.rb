# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      # This module defines methods used to evaluate the attributes of the Tag Type Definition
      module Attributes
        attr_reader :cached_in_model,
                    :owner_id_field,
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

        def cached_in_model_field
          @cached_in_model_field ||= cache_hash.fetch(:field) { "cached_#{tag_list_name}" }
        end

        def cached_in_model_as_list?
          @cached_in_model_as_list ||= cache_hash.fetch(:as_list, true)
        end

        alias preserve_tag_order? preserve_tag_order
        alias cached_in_model? cached_in_model
        alias force_lowercase? force_lowercase
        alias force_parameterize? force_parameterize
        alias remove_unused_tags? remove_unused_tags

        def tagger?
          instance_variable_defined?(:@tagger)
        end

        def tag_list_uses_default_tagger?
          return false if !tagger? || default_tagger_method.blank?

          tagger_params.fetch(:tag_list_uses_default_tagger, false)
        end

        def default_tagger_method
          return nil unless tagger?

          tagger_params[:default_tagger]
        end

        # :reek:FeatureEnvy
        # :reek:DuplicateMethodCall
        def taggable_default(taggable)
          default_list = default

          return unless default_list.present?

          default_list          = default_list.dup
          default_list.taggable = taggable

          default_list
        end

        def default_tagger(taggable)
          return nil if default_tagger_method.nil?
          return nil if taggable.blank?

          taggable.public_send(default_tagger_method)
        end

        def tag_list_default_tagger(taggable)
          return nil unless tag_list_uses_default_tagger?

          default_tagger(taggable)
        end

        private

        def cache_hash
          @cache_hash ||= cached_in_model.is_a?(Hash) ? cached_in_model : {}
        end

        def tagger_params
          return @tagger_params if defined?(@tagger_params)

          params = instance_variable_get(:@tagger)

          @tagger_params = if tagger? && params.is_a?(Hash)
                             params.with_indifferent_access
                           else
                             HashWithIndifferentAccess.new
                           end
        end

        def default_value=(value)
          dup_value       = Array.wrap(value).dup
          options         = dup_value.extract_options!.dup
          options[:parse] = options.fetch(:parse, true)

          @default = ActsAsTaggableOnMongoid::TagList.new self, *dup_value, options
        end
      end
    end
  end
end
