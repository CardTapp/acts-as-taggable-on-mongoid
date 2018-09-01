# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  ##
  # Returns a new TagList using the given tag string.
  #
  # Example:
  # tag_list = ActsAsTaggableOn::GenericParser.new.parse("One , Two, Three")
  # tag_list # ["One", "Two", "Three"]
  class GenericParser
    attr_reader :tags

    def initialize(tag_list)
      @tags = tag_list
    end

    def parse
      [].tap do |tag_list|
        tag_list.concat tags.split(",").map(&:strip).reject(&:empty?)
      end
    end

    def self.stringify_tag_list(*tag_list)
      tag_list.join(",")
    end
  end
end
