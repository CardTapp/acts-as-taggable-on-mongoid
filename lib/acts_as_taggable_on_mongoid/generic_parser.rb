# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  ##
  # Returns a new list of tags (array of strings) using the given tag string.
  #
  # Example:
  # tag_list = ActsAsTaggableOn::GenericParser.new.parse("One , Two, Three")
  # tag_list # ["One ", " Two", " Three"]
  #
  # All parsers are required to support two methods:
  #   * parse - parse the tag_list into an array of strings
  #   * to_s - return a parsed array of tags (may be passed in parsed) in a format that
  #            is suitable for parsing.
  #
  #            NOTE:  The ablitity to parse a list of tags and convert it to a string then back to
  #                   the same list of tags is dependent on the complexity of the parser.  This is
  #                   not actually assumed to be true, though it is best if it is.
  #
  # Cleansing the list of tags for the tag is the responsibility of the tags TagList which knows
  # if the tags need to be stripped, downcased, etc.  The parser need only return an array of
  # strings that are split out.
  class GenericParser
    attr_reader :tags

    DEFAULT_DELIMITER = ","

    def initialize(*tag_list)
      @tags = tag_list.flatten
    end

    def parse
      @tags = [].tap do |tag_list|
        tags.each do |tag|
          tag_list.concat tag.split(DEFAULT_DELIMITER).map(&:strip).reject(&:empty?)
        end
      end.flatten
    end

    def to_s
      tags.join(DEFAULT_DELIMITER)
    end
  end
end
