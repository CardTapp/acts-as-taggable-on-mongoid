# frozen_string_literal: true

# require_relative 'tagged_with_query'

# TODO: to_json override.  I'm worried about adding the tag_list to the attributes because it could then save to the
#       model or raise an exception if the model doesn't allow attributes that aren't fields.
#       Instead, I think I need to override the to_json so that it outputs the tag list also.
#
#       Maybe/maybe not.  I don't know if the tag_list should be a part of the json automatically or not.
module ActsAsTaggableOnMongoid
  module Taggable
    module Core
      extend ActiveSupport::Concern

      DYNAMIC_MODULE_NAME = :DynamicAttributes

      included do
        # TODO: allow custom contexts
        # attr_writer :custom_contexts

        after_save :save_tags
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

      def reload(*args)
        self.class.tag_types.each do |_tag_name, tag_definition|
          instance_variable_set tag_definition.all_tag_list_variable_name, nil
          instance_variable_set tag_definition.tag_list_variable_name, nil
        end

        super(*args)
      end

      private

      def tag_list_cache_set_on(tag_definition)
        variable_name = tag_definition.tag_list_variable_name

        instance_variable_defined?(variable_name) && instance_variable_get(variable_name)
      end

      def tag_list_cache_on(tag_type_definition)
        variable_name = tag_type_definition.tag_list_variable_name

        # if instance_variable_get(variable_name)
        #   instance_variable_get(variable_name)
        # elsif cached_tag_list_on(tag_type_definition) && ensure_included_cache_methods! && self.class.caching_tag_list_on?(tag_type_definition)
        #   instance_variable_set(variable_name, tag_type_definition.parse(cached_tag_list_on(tag_type_definition)))
        # else
        #   instance_variable_set(variable_name, ActsAsTaggableOnMongoid::TagList.new(tag_type_definition, tags_on(tag_type_definition).map(&:name)))
        # end

        instance_variable_get(variable_name) ||
            instance_variable_set(variable_name,
                                  ActsAsTaggableOnMongoid::TagList.new(tag_type_definition, tags_on(tag_type_definition).map(&:tag_name)))
      end

      def tag_list_on(tag_type_definition)
        # add_custom_context(tag_type_definition)
        tag_list_cache_on(tag_type_definition)
      end

      def all_tags_list_on(tag_type_definition)
        variable_name   = tag_type_definition.all_tag_list_variable_name
        cached_variable = instance_variable_get(variable_name)

        return cached_variable if instance_variable_defined?(variable_name) && cached_variable

        instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(tag_type_definition, all_tags_on(tag_type_definition).map(&:name)).freeze)
      end

      ##
      # Returns all tags of a given context
      def all_tags_on(tag_definition)
        tag_definition.tags_table.for_tag(tag_definition).to_a
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(tag_type_definition)
        # scope = send(tag_type_definition.taggings_name).where(context: tag_type_definition.tag_type, tagger_id: nil)
        scope = send(tag_type_definition.taggings_name).where(context: tag_type_definition.tag_type)

        # # when preserving tag order, return tags in created order
        # # if we added the order to the association this would always apply
        scope = scope.order_by(:created_at.asc, :id.asc) if tag_type_definition.preserve_tag_order?

        scope
      end

      def tag_list_set(new_list)
        # add_custom_context(tag_type_definition, owner)

        instance_variable_set(new_list.tag_type_definition.tag_list_variable_name, new_list)
      end

      ##
      # Find existing tags or create non-existing tags
      def load_tags(tag_definition, tag_list)
        tag_definition.tags_table.find_or_create_all_with_like_by_name(tag_definition, tag_list)
      end

      def save_tags
        # Don't call save_tags again if a related classes save while processing this funciton causes this object to re-save.
        return if @saving_tag_list

        @saving_tag_list = true

        self.class.tag_types.each_value do |tag_definition|

          next unless tag_list_cache_set_on(tag_definition)

          # List of currently assigned tag names
          tag_list = tag_list_cache_on(tag_definition).uniq

          # Find existing tags or create non-existing tags:
          tags               = find_or_create_tags_from_list_with_context(tag_definition, tag_list)
          current_tags       = tags_on(tag_definition).map(&:tag).compact
          old_tags           = current_tags - tags
          new_tags           = tags - current_tags

          old_tags, new_tags = preserve_tag_list_order(tags, current_tags, old_tags, new_tags) if tag_definition.preserve_tag_order?

          # Destroy old taggings:
          if old_tags.present?
            send(tag_definition.taggings_name).by_context(tag_definition.tag_type).where(:tag_name.in => old_tags.map(&:name)).destroy_all
          end

          # Create new taggings:
          new_tags.each do |tag|
            send(tag_definition.taggings_name).create!(tag_name: tag.name, context: tag_definition.tag_type, taggable: self, tag: tag)
          end
        end

        @saving_tag_list = false

        true
      end

      def preserve_tag_list_order(tags, current_tags, old_tags, new_tags)
        shared_tags = current_tags & tags

        if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
          index = shared_tags.each_with_index { |_, i| break i unless shared_tags[i] == tags[i] }

          # Update arrays of tag objects
          old_tags |= current_tags[index...current_tags.size]
          new_tags |= current_tags[index...current_tags.size] & shared_tags

          # Order the array of tag objects to match the tag list
          new_tags = tags.map do |t|
            new_tags.find { |n| n.name == t.name }
          end.compact
        end

        [old_tags, new_tags]
      end

      def dirtify_tag_list(tagging)
        definition = self.class.tag_definition(tagging.context)

        attribute_will_change! definition.tag_list_name
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
      # @param [Array<String>] tag_list Tags to find or create
      # @param [Symbol] context The tag context for the tag_list
      def find_or_create_tags_from_list_with_context(tag_definition, tag_list)
        load_tags(tag_definition, tag_list)
      end
    end
  end
end
