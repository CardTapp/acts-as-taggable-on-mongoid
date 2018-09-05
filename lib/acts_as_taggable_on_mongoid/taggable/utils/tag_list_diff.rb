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
      class TagListDiff
        attr_reader :old_tags,
                    :new_tags,
                    :tag_definition,
                    :current_tags,
                    :shared_tags,
                    :tags

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

        def create_new_tags
          new_tags.each do |tag|
            send(tag_definition.taggings_name).create!(tag_name: tag.name, context: tag_definition.tag_type, taggable: self, tag: tag)
          end
        end

        def destroy_old_tags
          return if old_tags.blank?

          send(tag_definition.taggings_name).by_context(tag_definition.tag_type).where(:tag_name.in => old_tags.map(&:name)).destroy_all
        end

        private

        def preserve_tag_list_order
          return unless tag_definition.preserve_tag_order?

          @shared_tags = current_tags & tags

          return if share_tags_sorted?

          index = first_ordered_difference

          # Update arrays of tag objects
          @old_tags |= current_tags[index..-1]

          preserve_new_tag_list_order
        end

        def share_tags_sorted?
          shared_tags.none? || tags[0...shared_tags.size] == shared_tags
        end

        def preserve_new_tag_list_order
          preserved_tags = new_tags | current_tags[index..-1] & shared_tags

          # Order the array of tag objects to match the tag list
          @new_tags = tags.map do |t|
            preserved_tags.find { |n| n.name == t.name }
          end.compact
        end

        def first_ordered_difference
          index = 0
          shared_tags.while(index < shared_tags.length) do
            break unless shared_tags[index] == tags[index]

            index += 1
          end
          index
        end
      end
    end
  end
end
