# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Tagger
    # A module defining Tagger methods allowing the Tagger object to tag Taggable objects
    #
    # This module is dynamically added to a model when the model calls acts_as_tagger

    # :reek:DataClump
    module TagMethods
      ##
      # Taggs the passed in taggable object with the tag values passed in to it.
      #
      # Parameters:
      #   taggable        - the object to tag
      #   non-hash values - the values to use to tag taggable with
      #   {options}
      #     with:         - Alternative to non-hash values.  If found as an option it will replace
      #                     any non-hash values.  If not specified, any tags for this tagger will be
      #                     removed from taggable
      #     on:           - the tag list within taggable to be set.  This will default to `:tag`
      #     parse:        - Boolean indicating if the tags should be parsed.  This will default to "true"
      #     parser:       - Class to be used to parse the values.
      #     skip_save:    - Do not save the taggable object with the new tagging.
      def tag(taggable, *args)
        options = atom_tag(taggable, *args)

        taggable.save unless options[:skip_save]
      end

      ##
      # tag, but uses `save!` instead of `save` to save the taggable model.
      def tag!(taggable, *args)
        options = atom_tag(taggable, *args)

        taggable.save! unless options[:skip_save]
      end

      def self.atom_extract_tag_options(set_list)
        options = set_list.extract_options!

        options.assert_valid_keys :with,
                                  :on,
                                  :replace,
                                  :parse,
                                  :parser,
                                  :skip_save

        options[:parse] = options.fetch(:parse, true) || options.key?(:parser)

        options
      end

      private

      # :reek:FeatureEnvy
      def atom_tag(taggable, *args)
        set_list = args.dup
        options  = ActsAsTaggableOnMongoid::Tagger::TagMethods.atom_extract_tag_options(set_list)
        set_list = Array.wrap(options[:with]) if options.key?(:with)

        tag_list     = taggable.public_send("tagger_#{options.fetch(:on, :tag)}_list", self)
        list_options = options.slice(:parse, :parser)
        if options[:replace]
          tag_list.set(*set_list, list_options)
        else
          tag_list.add(*set_list, list_options)
        end

        options
      end
    end
  end
end