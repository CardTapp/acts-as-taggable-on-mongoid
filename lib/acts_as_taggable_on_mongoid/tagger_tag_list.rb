# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  # A hash like collection of tag lists grouped by tagger

  # :reek:RepeatedConditional
  class TaggerTagList
    include Comparable

    delegate :keys,
             :values,
             :length,
             :delete,
             :clear,
             :each,
             :each_with_object,
             :detect,
             :reject!,
             :any?,
             :each_value,
             :map,
             to: :tagger_tag_lists

    attr_reader :taggable,
                :tag_definition

    def initialize(tag_definition, taggable)
      @tag_definition = tag_definition
      @taggable       = taggable

      @tagger_tag_lists = Hash.new { ActsAsTaggableOnMongoid::TagList.new_taggable_list(tag_definition, taggable) }
    end

    def compact!
      reject! { |_key, value| value.blank? }
      self
    end

    def compact
      dup.compact!
    end

    def flatten
      list = ActsAsTaggableOnMongoid::TagList.new_taggable_list(tag_definition, taggable)

      each_value do |tag_list|
        list.concat(tag_list)
      end

      list
    end

    def <=>(other)
      compact!

      if other.is_a?(ActsAsTaggableOnMongoid::TagList)
        compare_to_tag_list(other)
      elsif other.is_a?(ActsAsTaggableOnMongoid::TaggerTagList)
        other.compact!

        compare_to_tagger_tag_list(other)
      else
        super(other)
      end
    end

    def [](tagger)
      list = tagger_tag_lists[tagger]

      list.tagger = tagger

      tagger_tag_lists[tagger] = list
    end

    def []=(tagger, value)
      tagger_list = self[tagger]

      if value.is_a?(ActsAsTaggableOnMongoid::TagList)
        tagger_list.set(value)
      else
        value           = Array.wrap(value).dup
        options         = value.extract_options!
        options[:parse] = options.fetch(:parse) { true }

        value = [*value, options]

        tagger_list.set(*value)
      end
    end

    def dup
      list = ActsAsTaggableOnMongoid::TaggerTagList.new(tag_definition, taggable)

      each do |tagger, tag_list|
        list[tagger].silent_concat(tag_list) if tag_list.present?
      end

      list
    end

    def taggable=(value)
      @taggable = value

      tagger_tag_lists.values.each do |tag_list|
        tag_list.taggable = taggable
      end
    end

    def notify_will_change
      return unless taggable

      taggable.tag_list_on_changed tag_definition
    end

    def blank?
      tagger_tag_lists.values.all?(&:blank?)
    end

    private

    attr_reader :tagger_tag_lists

    def compare_tagger_tag_list_properties(other)
      sub_compare = keys.length <=> other.keys.length
      return sub_compare unless sub_compare&.zero?

      taggable <=> other.taggable
    end

    def compare_to_tagger_tag_list(other)
      sub_compare = compare_tagger_tag_list_properties(other)
      return sub_compare unless sub_compare&.zero?

      any? do |key, tag_list|
        other_tag_list = other[key]

        sub_compare = if tag_definition.preserve_tag_order
                        tag_list <=> other_tag_list
                      else
                        tag_list.sort <=> other_tag_list.sort
                      end

        !sub_compare&.zero?
      end

      sub_compare
    end

    def compare_tag_list_properties(other)
      sub_compare = tagger_tag_lists.length <=> 1
      return sub_compare unless sub_compare&.zero?

      sub_compare = keys.first <=> other.tagger
      return sub_compare unless sub_compare&.zero?

      taggable <=> other.taggable
    end

    def compare_to_tag_list(other)
      sub_compare = compare_tag_list_properties(other)
      return sub_compare unless sub_compare&.zero?

      tagger_list = values.first
      if tag_definition.preserve_tag_order
        tagger_list <=> other
      else
        tagger_list.sort <=> other.sort
      end
    end
  end
end
