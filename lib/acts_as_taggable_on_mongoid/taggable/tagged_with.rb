# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # Include methods and scopes to a Taggable class to allow searching for Taggable objects.
    module TaggedWith
      extend ActiveSupport::Concern

      included do
        ##
        # Return a scope of objects that are tagged within the given context with the specified tags.
        #
        # @param tags The tags that we want to query for
        # @param [Hash] options A hash of options to alter you query:
        #                       * <tt>:on</tt> - The context to filter the query by. (default - all contexts)
        #                                        To allow broader compatibility with `ActsAsTaggableOn`, context can be an array of values
        #                                        for a set of tags that are equivalent enough (the parsing of the list is the same
        #                                        and they use the same taggings table.)
        #
        #                                        If you are trying to find values for a tag that downcases and one that doesn't, the
        #                                        code is unsure how to handle this and raises an exception.
        #                       * <tt>:exclude</tt> - if set to true, return objects that are *NOT* tagged with the specified tags
        #                       * <tt>:any</tt> - if set to true, return objects that are tagged with *ANY* of the specified tags
        #                       * <tt>:match_all</tt> - if set to true, return objects that are tagged with *ONLY* the specified tags
        #                       * <tt>:all</tt> - if set to true, return objects that are tagged with *ALL* of the specified tags
        #                                         If none of :any, :eclude, or :all are set, :all is the default.
        #                       * <tt>:start_at</tt> - Restrict the tags to those created on or after a certain time
        #                       * <tt>:end_at</tt> - Restrict the tags to those created before a certain time
        #                       * <tt>:wild</tt> - Match all passed in tags as a regex of /%tag%/
        #                       * <tt>:parse</tt> - Indicates if the tags should be parsed or not.
        #                       * <tt>:parser</tt> - The parser to be used to parse the tags.
        #
        #                 The following options are not currently supported yet:
        #                       * <tt>:order_by_matching_tag_count</tt> - if set to true and used with :any, sort by objects matching the most tags,
        #                                                                 descending
        #                       * <tt>:owned_by</tt> - return objects that are *ONLY* owned by the owner
        #                       * <tt>:order</tt> - Not supported because you cannot sort the results by
        #                                           the taggings in this implementation and an order on the taggable
        #                                           can easily be added by the consumer as needed.
        #
        # Example:
        #   User.tagged_with("awesome", "cool", on: tags)                     # Users that are tagged with awesome and cool
        #   User.tagged_with("awesome", "cool", on: tags, :exclude => true)   # Users that are not tagged with awesome or cool
        #   User.tagged_with("awesome", "cool", on: tags, :any => true)       # Users that are tagged with awesome or cool
        #   User.tagged_with("awesome", "cool", on: tags, :any => true, :order_by_matching_tag_count => true)  # Sort by users who match the most
        #                                                                                                        tags, descending
        #   User.tagged_with("awesome", "cool", on: tags, :match_all => true) # Users that are tagged with just awesome and cool
        #   User.tagged_with("awesome", "cool", on: tags, :owned_by => foo ) # Users that are tagged with just awesome and cool by 'foo'
        #   User.tagged_with("awesome", "cool", on: tags, :owned_by => foo, :start_at => Date.today ) # Users that are tagged with just awesome,
        #                                                                                               cool by 'foo' and starting today

        scope :tagged_with, (->(*tags) { where ::ActsAsTaggableOnMongoid::Taggable::TaggedWithQuery.new(self, *tags).build })
      end
    end
  end
end
