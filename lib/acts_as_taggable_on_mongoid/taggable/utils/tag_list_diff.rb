# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    module Utils
      # A utility class for creating new taggings and deleting old taggings when the list of tags for an object
      # is changed and that change is saved.
      #
      # The class will respect the preserve_tag_order? option for the tag and will delete any existing taggings
      # and recreate them from the first moved tag onwards.
      #
      # If order is not preserved, it will simply delete unused taggings and add new taggings that do not already
      # exist.

      # :reek:TooManyInstanceVariables
      # :reek:InstanceVariableAssumption
      class TagListDiff
        def initialize(tag_definition:, tags:, current_tags:)
          @tag_definition = tag_definition
          @tags           = tags
          @current_tags   = current_tags

          @old_tags = {}
          @new_tags = {}
        end

        def call
          @old_tags = current_tags - tags
          @new_tags = tags - current_tags

          preserve_tag_list_order
        end

        def create_new_tags(taggable)
          new_tags.each do |tag|
            tagging = taggable.
                public_send(tag_definition.taggings_name).
                new(tag_name: tag.name, context: tag_definition.tag_type, taggable: taggable, tag: tag)

            next if tagging.save
            next if ignore_tagging_error(tagging)

            # re-raise error.
            tagging.save!
          end
        end

        def destroy_old_tags(taggable)
          return if old_tags.blank?

          taggable.
              public_send(tag_definition.taggings_name).
              by_context(tag_definition.tag_type).
              where(:tag_name.in => old_tags.map(&:name)).
              destroy_all
        end

        private

        attr_reader :old_tags,
                    :new_tags,
                    :tag_definition,
                    :current_tags,
                    :shared_tags,
                    :tags

        # :reek:UtilityFunction
        # ignore the error if it is that the tagging already exists.
        def ignore_tagging_error(tagging)
          tagging_errors = tagging.errors

          tagging_errors.count == 1 &&
              tagging.tag_name.present? &&
              tagging.tag.present? &&
              (tagging_errors.key?(:tag_name) || tagging_errors.key?(:tag_id))
        end

        def preserve_tag_list_order
          return unless tag_definition.preserve_tag_order?

          @shared_tags = current_tags & tags

          return if share_tags_sorted?

          # Update arrays of tag objects
          @old_tags |= current_tags[first_ordered_difference..-1]

          preserve_new_tag_list_order
        end

        def share_tags_sorted?
          shared_tags.none? || tags[0...shared_tags.size] == shared_tags
        end

        # :reek:NestedIterators
        def preserve_new_tag_list_order
          preserved_tags = new_tags | current_tags[first_ordered_difference..-1] & shared_tags

          # Order the array of tag objects to match the tag list
          @new_tags = tags.map do |tag|
            preserved_tags.find { |preserved_tag| preserved_tag.name == tag.name }
          end.compact
        end

        def first_ordered_difference
          return @first_ordered_difference if defined?(@first_ordered_difference)

          index = 0

          while index < shared_tags.length
            break unless shared_tags[index] == tags[index]

            index += 1
          end

          @first_ordered_difference = index
        end
      end
    end
  end
end
