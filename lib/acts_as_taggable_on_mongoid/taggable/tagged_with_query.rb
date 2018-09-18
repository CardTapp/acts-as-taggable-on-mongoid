# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # A class finding all Taggable objects for the passed in tags based on the passed in parameters.
    # Details for how the query will work are in the TaggedWith module.
    class TaggedWithQuery
      attr_reader :taggable_class,
                  :tags,
                  :options,
                  :tag_definition

      def initialize(taggable_class, *tags)
        new_tags        = tags.dup
        @taggable_class = taggable_class
        @options        = new_tags.extract_options!.dup
        @tags           = new_tags

        cleanup_options

        context         = on_context(*options[:on])
        @tag_definition = taggable_class.tag_types[context]
      end

      def build
        klass = if options[:exclude].present?
                  ExcludeTagsQuery
                elsif options[:any].present?
                  AnyTagsQuery
                elsif options[:match_all]
                  MatchAllTagsQuery
                else
                  AllTagsQuery
                end

        klass.new(tag_definition, tag_list, options).build
      end

      private

      def cleanup_options
        options[:on]    = Array.wrap(options[:on] || options.delete(:context))
        options[:parse] = options.fetch(:parse) { true } || options.key?(:parser)

        validate_options
      end

      def validate_options
        options.assert_valid_keys :parse,
                                  :parser,
                                  :wild,
                                  :exclude,
                                  :match_all,
                                  :all,
                                  :any,
                                  :on,
                                  :start_at,
                                  :end_at
      end

      def on_context(*contexts)
        test_contexts   = (contexts.presence || taggable_class.tag_types.keys).flatten
        primary_context = test_contexts.first

        test_contexts.each do |context|
          raise "conflicting context definitions" if conflicting_context?(primary_context, context)
        end

        primary_context
      end

      # :reek:FeatureEnvy

      def conflicting_context?(left, right)
        return false if left == right

        tag_types = taggable_class.tag_types

        tag_types[left].conflicts_with? tag_types[right]
      end

      def tag_list
        @tag_list ||= build_tag_list
      end

      def build_tag_list
        return [] if tag_definition.blank?

        tag_list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *tags, options.slice(:parse, :parser))
        tag_list = tag_list.map { |tag| /#{tag}/ } if options[:wild]

        tag_list
      end
    end
  end
end
