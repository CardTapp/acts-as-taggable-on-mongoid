# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    extend ActiveSupport::Concern

    class_methods do
      # # tag options:
      # #   * preserve_tag_order - The tag(s) defined will preserve the tag order.
      # #   * parser             - The parser for the tag(s) defined.

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

      # ##
      # # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
      # #
      # # Example:
      # #   class Book < ActiveRecord::Base
      # #     acts_as_ordered_taggable
      # #   end
      # def acts_as_ordered_taggable(options = {})
      #   acts_as_ordered_taggable_on :tags, options
      # end

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
        options = tag_types.extract_options!

        taggable_on(*tag_types, options.merge(preserve_tag_order: true))
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
         # include Collection - not sure we will need as done here.  Need to think more on this one.
         # include Cache - TODO: Add this.
         # include Ownership - TODO: Add this.
         # include Related - TODO: Add this.
         ActsAsTaggableOnMongoid::Taggable::ListTags].each do |include_module|
          include include_module unless included_modules.include?(include_module)
        end

        options = tag_types.extract_options!

        tag_types.each do |tag_type|
          define_tag tag_type, options
        end
      end
    end
  end
end
