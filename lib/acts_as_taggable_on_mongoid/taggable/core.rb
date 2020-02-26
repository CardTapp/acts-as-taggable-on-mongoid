# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # A collection of generic methods which use the tag definition to perform actions.
    #
    # These methods are called by the individual tag generated methods to do their work so that
    # the code can be defined in only one location and "shared" by all tags rather than putting the code
    # and definitions into the dynamically defined methods directly.
    #
    # This module actually consists almost exclusively of utility functions

    # :reek:FeatureEnvy
    # :reek:UtilityFunction
    module Core
      extend ActiveSupport::Concern

      DYNAMIC_MODULE_NAME = :DynamicAttributes

      included do
        # TODO: allow custom contexts
        # attr_writer :custom_contexts

        after_save :save_tags
        before_save :save_cached_tag_lists
      end

      class_methods do
        def taggable_mixin
          # https://thepugautomatic.com/2013/07/dsom/
          # Provides a description of what we're doing here and why.
          if const_defined?(DYNAMIC_MODULE_NAME, false)
            mod = const_get(DYNAMIC_MODULE_NAME)
          else
            mod = const_set(DYNAMIC_MODULE_NAME, Module.new)

            include mod
          end

          mod
        end
      end

      def apply_post_processed_defaults
        defaults = super

        defaults |= set_tag_list_defaults

        defaults
      end

      private

      def set_tag_list(tag_definition, new_tags)
        dup_tags        = Array.wrap(new_tags).dup
        options         = dup_tags.extract_options!.dup
        options[:parse] = options.fetch(:parse) { true }

        new_list          = tag_definition.parse(*dup_tags, options)
        new_list.taggable = self
        new_list.tagger   = tag_definition.tag_list_default_tagger(self) unless options.key?(:tagger)

        mark_tag_list_changed(new_list)
        tag_list_set(new_list)
      end

      def get_tag_list_change(tag_definition)
        tag_list_name = tag_definition.tag_list_name

        return nil unless public_send("#{tag_list_name}_changed?")

        changed_value = new_record? ? tag_definition.default_tagger_tag_list(self) : changed_attributes[tag_list_name]
        current_value = tag_list_cache_on(tag_definition)

        return nil if (changed_value <=> current_value)&.zero?

        tag_list_change_value(tag_definition, changed_value, current_value)
      end

      def tag_list_change_value(tag_definition, changed_value, current_value)
        if tag_definition.tagger?
          [changed_value.dup, current_value.dup]
        else
          [changed_value[nil].dup, current_value[nil].dup]
        end
      end

      def get_tag_list_changed(tag_definition)
        tag_list_name = tag_definition.tag_list_name

        return false unless changed_attributes.key?(tag_list_name)

        changed_value = new_record? ? tag_definition.default_tagger_tag_list(self) : changed_attributes[tag_list_name]
        current_value = tag_list_cache_on(tag_definition)

        !(changed_value <=> current_value)&.zero?
      end

      def get_tag_list_was(tag_definition)
        default_tagger = tag_definition.tag_list_default_tagger(self)
        return tag_definition.default_tagger_tag_list(self)[default_tagger].dup if new_record?

        tag_list_name = tag_definition.tag_list_name

        if public_send "#{tag_list_name}_changed?"
          changed_attributes[tag_list_name][default_tagger].dup
        else
          public_send(tag_list_name).dup
        end
      end

      def get_tag_lists_was(tag_definition)
        return tag_definition.default_tagger_tag_list(self).dup if new_record?

        tag_list_name = tag_definition.tag_list_name

        if public_send "#{tag_list_name}_changed?"
          changed_attributes[tag_list_name].dup
        else
          public_send(tag_definition.tagger_tag_lists_name).dup
        end
      end

      def get_tagger_list_was(tag_definition, tagger)
        return nil unless tag_definition.tagger?
        return tag_definition.default_tagger_tag_list(self)[tagger].dup if new_record?

        tag_list_name = tag_definition.tag_list_name

        if public_send "#{tag_list_name}_changed?"
          changed_attributes[tag_list_name][tagger].dup
        else
          public_send(tag_definition.tagger_tag_list_name, tagger).dup
        end
      end

      def tag_list_cache_set_on(tag_definition)
        variable_name = tag_definition.tag_list_variable_name

        instance_variable_defined?(variable_name) && instance_variable_get(variable_name)
      end

      def tag_list_cache_on(tag_definition)
        variable_name = tag_definition.tag_list_variable_name

        # if instance_variable_get(variable_name)
        #   instance_variable_get(variable_name)
        # elsif cached_tag_list_on(tag_definition) && ensure_included_cache_methods! && self.class.caching_tag_list_on?(tag_definition)
        #   instance_variable_set(variable_name, tag_definition.parse(cached_tag_list_on(tag_definition)))
        # else
        #   tag_list_set(ActsAsTaggableOnMongoid::TagList.new(tag_definition, tags_on(tag_definition).map(&:tag_name)))
        # end

        instance_variable_get(variable_name) ||
            tagger_tag_list_set(tagger_tag_list_from_taggings(tag_definition, all_tags_on(tag_definition)))
      end

      def tagger_tag_list_from_taggings(tag_definition, taggings)
        tagger_tag_list = ActsAsTaggableOnMongoid::TaggerTagList.new(tag_definition, self)

        taggings.each do |tagging|
          tagger_tag_list[tagging.tagger].silent_concat [tagging.tag_name]
        end

        tagger_tag_list
      end

      def tag_list_on(tag_definition)
        # add_custom_context(tag_definition)

        tag_list_cache_on(tag_definition)[tag_definition.tag_list_default_tagger(self)]
      end

      def all_tags_list_on(tag_definition)
        tag_list_cache_on(tag_definition).flatten
      end

      ##
      # Returns all tags of a given context
      def all_tags_on(tag_definition)
        scope = public_send(tag_definition.taggings_name).where(context: tag_definition.tag_type)

        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order_by(*tag_definition.taggings_order) if tag_definition.preserve_tag_order?

        scope
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(tag_definition)
        scope = public_send(tag_definition.taggings_name).where(context: tag_definition.tag_type, :tagger_id.exists => false)

        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order_by(*tag_definition.taggings_order) if tag_definition.preserve_tag_order?

        scope
      end

      ##
      # Returns all tags that are owned by a given tagger of a given context
      def tagger_tags_on(tagger, tag_definition)
        scope = public_send(tag_definition.taggings_name).where(context: tag_definition.tag_type, tagger: tagger)

        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order_by(*tag_definition.taggings_order) if tag_definition.preserve_tag_order?

        scope
      end

      def mark_tag_list_changed(new_list)
        tag_definition   = new_list.tag_definition
        current_tag_list = tag_list_cache_on(tag_definition)

        return if current_tag_list == new_list

        current_tag_list.notify_will_change
      end

      def tagger_tag_list_set(new_list)
        instance_variable_set(new_list.tag_definition.tag_list_variable_name, new_list)
      end

      def tag_list_set(new_list)
        # add_custom_context(tag_definition, owner)

        new_list.taggable = self
        tag_definition    = new_list.tag_definition
        tagger_tag_list   = ActsAsTaggableOnMongoid::TaggerTagList.new(tag_definition, self)

        tagger_tag_list[new_list.tagger] = new_list

        instance_variable_set(tag_definition.tag_list_variable_name, tagger_tag_list)
      end

      ##
      # Find existing tags or create non-existing tags
      def load_tags(tag_definition, tagger_tag_list)
        tag_definition.tags_table.find_or_create_tagger_list_with_like_by_name(tag_definition, tagger_tag_list)
      end

      def set_tag_list_defaults
        return [] unless new_record?

        defaulted_values = []
        tag_types.each_value do |tag_definition|
          next if instance_variable_defined?(tag_definition.tag_list_variable_name)

          default = tag_definition.taggable_default(self)
          next unless default.present?

          set_default_value(tag_definition, default)

          defaulted_values << tag_definition.tag_list_name
        end

        defaulted_values
      end

      def set_default_value(tag_definition, default)
        public_send(tag_definition.tagger_tag_lists_name)[default.tagger] = default
        changed_attributes.delete tag_definition.tag_list_name
      end

      def save_tags
        # Don't call save_tags again if a related classes save while processing this funciton causes this object to re-save.
        return if @saving_tag_list

        @saving_tag_list = true

        tag_types.each_value do |tag_definition|
          next unless tag_list_cache_set_on(tag_definition)

          # List of currently assigned tag names
          tag_list_diff = extract_tag_list_changes(tag_definition)

          # Destroy old taggings:
          tag_list_diff.destroy_old_tags self

          # Create new taggings:
          tag_list_diff.create_new_tags self
        end

        @saving_tag_list = false

        true
      end

      def extract_tag_list_changes(tag_definition)
        tag_list = tag_list_cache_on(tag_definition)

        # Find existing tags or create non-existing tags:
        tags         = find_or_create_tags_from_list_with_context(tag_definition, tag_list)
        current_tags = all_tags_on(tag_definition)

        tag_list_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new tag_definition: tag_definition,
                                                                                  tags:           tags,
                                                                                  current_tags:   current_tags

        tag_list_diff.call

        tag_list_diff
      end

      def dirtify_tag_list(tagging)
        tag_definition = tag_types[tagging.context]

        return unless tag_definition

        attribute_will_change! tag_definition.tag_list_name
      end

      ##
      # Imported from `ActsAsTaggableOn`.  It is simply easier to define a custom Tag class and define
      # the tag to use that Tag class.
      #
      # Override this hook if you wish to subclass {ActsAsTaggableOn::Tag} --
      # context is provided so that you may conditionally use a Tag subclass
      # only for some contexts.
      #
      # @example Custom Tag class for one context
      #   class Company < ActiveRecord::Base
      #     acts_as_taggable_on :markets, :locations
      #
      #     def find_or_create_tags_from_list_with_context(tag_list)
      #       if context.to_sym == :markets
      #         MarketTag.find_or_create_all_with_like_by_name(tag_list)
      #       else
      #         super
      #       end
      #     end
      #
      # @param [Array<String>] tagger_tag_list Tags to find or create grouped by tagger
      # @param [Symbol] tag_definition The tag context for the tag_list
      def find_or_create_tags_from_list_with_context(tag_definition, tagger_tag_list)
        load_tags(tag_definition, tagger_tag_list)
      end
    end
  end
end
