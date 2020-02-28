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
    module Cache
      def save_cached_tag_lists
        tag_types.each_value do |tag_definition|
          next unless tag_definition.cached_in_model?
          next unless tag_list_cache_set_on(tag_definition)

          list = all_tags_list_on(tag_definition)

          list = list.to_s unless tag_definition.cached_in_model_as_list?

          public_send("#{tag_definition.cached_in_model_field}=", list)
        end
      end
    end
  end
end
