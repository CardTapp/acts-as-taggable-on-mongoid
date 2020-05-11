# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  # This module defines the class methods to be added to the Mongoid model so that
  # tags can be defined on and added to a model.
  #
  # When a tag is added to a model, additional modules will be included to add methods that
  # are needed only if a tag is actually being used.
  module Taggable
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength

    class_methods do
      # Options include:
      #   * parser
      #     The class to be used to parse strings.
      #   * preserve_tag_order
      #     If true, the _list accessor will save and returns tags in the order they are added to the object.
      #   * cached_in_model
      #     If true, a field is added to de-normalize/cache the list into.  Can also be a hash with options:
      #       field: The name of the field to cache the list in
      #       as_list: true/false - If the cached value should be an Array or a String.  No order is guaranteed
      #                             in either case.
      #                             Defaults to true.
      #   * owner_id_field
      #     If cached_in_model is true, if a tag is owned, this is the field that will be checked for a matching
      #     owner ID for tag updates and deletes.
      #   * force_lowercase
      #     If true, values stored for tags will first be downcased to make the values effectively case-insensitive
      #   * force_parameterize
      #     If true, values stored for tags will be parameterized
      #   * remove_unused_tags
      #     If true, when there are no more taggings for a tag, the tag will be destroyed
      #   * tags_table
      #     The class to use for Tags
      #   * taggings_table
      #     The class to use for Taggings
      #   * default
      #     A default value.  Any value that can be used for list assignment or adding values to a list
      #     can be used.  If custom options like `parse` or `parser` are to be used for the default, the value
      #     must be passed in as an array with a hash as the last value.  Like list setters, parsing is assumed.
      #     Example:  default: ["this, is, a, list", parser: ActsAsTaggableOnMongoid::GenericParser]
      #   * tagger
      #     Multiple variants
      #
      #     true - If simply the value `true`, the tag list supports owners.  No default owner will be used when
      #            setting or accessing tag_lists
      #     Hash - A hash of values defining default options for the tag list:
      #            * default_tagger
      #              A symbol of a method on the taggable object that owns the HashList which is used to determine
      #              the default owner for a list if an owner is not specified.
      #            * tag_list_uses_default_tagger
      #              true/false indicating if a non-owner method that returns a tag_list should assume the default_tagger
      #              or return items with no owner.

      ##
      # This is an alias for calling <tt>acts_as_taggable_on :tags</tt>.
      #
      # Example:
      #   class Book < ActiveRecord::Base
      #     acts_as_taggable
      #   end
      def acts_as_taggable(options = {})
        acts_as_taggable_on :tags, options
      end

      ##
      # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
      #
      # Example:
      #   class Book < ActiveRecord::Base
      #     acts_as_ordered_taggable
      #   end
      def acts_as_ordered_taggable(options = {})
        acts_as_ordered_taggable_on :tags, options
      end

      ##
      # Make a model taggable on specified contexts.
      #
      # @param [Array] tag_types An array of taggable contexts
      #
      # Example:
      #   class User < ActiveRecord::Base
      #     acts_as_taggable_on :languages, :skills
      #   end
      def acts_as_taggable_on(*tag_types)
        taggable_on(*tag_types)
      end

      ##
      # Make a model taggable on specified contexts
      # and preserves the order in which tags are created.
      #
      # An alias for acts_as_taggable_on *tag_types, preserve_tag_order: true
      #
      # @param [Array] tag_types An array of taggable contexts
      #
      # Example:
      #   class User < ActiveRecord::Base
      #     acts_as_ordered_taggable_on :languages, :skills
      #   end
      def acts_as_ordered_taggable_on(*tag_types)
        dup_tag_types = tag_types.dup
        options       = dup_tag_types.extract_options!.dup

        taggable_on(*dup_tag_types, options.merge(preserve_tag_order: true))
      end

      private

      # Make a model taggable on specified contexts
      # and optionally preserves the order in which tags are created
      #
      # Separate methods used above for backwards compatibility
      # so that the original acts_as_taggable_on method is unaffected
      # as it's not possible to add another argument to the method
      # without the tag_types being enclosed in square brackets
      #
      # NB: method overridden in core module in order to create tag type
      #     associations and methods after this logic has executed
      #
      def taggable_on(*tag_types)
        # if we are actually defining tags on a module, add these modules to add hooks and global methods
        # used by tagging.  We only add them dynamically like this so that they don't bloat the model
        # and add hooks/callbacks that aren't needed without tags.
        [ActsAsTaggableOnMongoid::Taggable::Core,
         ActsAsTaggableOnMongoid::Taggable::Changeable,
         ActsAsTaggableOnMongoid::Taggable::TaggedWith,
         # include Collection - not sure we will need as done here.  Need to think more on this one.
         ActsAsTaggableOnMongoid::Taggable::Cache,
         # include Related - TODO: Add this.
         ActsAsTaggableOnMongoid::Taggable::TaggerRelation,
         ActsAsTaggableOnMongoid::Taggable::ListTags].each do |include_module|
          include include_module unless included_modules.include?(include_module)
        end

        dup_tag_types = tag_types.dup
        options       = dup_tag_types.extract_options!.dup
        dup_tag_types.flatten!

        dup_tag_types.each do |tag_type|
          next if tag_type.blank?

          define_tag tag_type, options
        end
      end
    end

    # rubocop:enable Metrics/BlockLength
  end
end
