# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  ##
  # Returns a new Array using the given tag string.
  #
  # Parsing is done based on an array of delimiters that is set at the class level.  Parsing will split
  # on any delimiter value that is found.  By default strings are split by commas (,).
  #
  # To allow more complex strings, parsing will parse out quoted strings (either single or double quoted)as a block.
  # (This is only partially implemented for quick not accurate/complete implementation that is
  # "good enough" for most expected tags.)
  #
  # examples:
  #
  # # Delimiters
  # # You can set the delimiters to a single value:
  # DefaultParser.delimiter = "\\|"
  #
  # # You can set the delimiters to an array value:
  # DefaultParser.delimiter = %w[\\| , break_here]
  #
  # # Parsing a string by multiple delimters
  # DefaultParser.new("a|stupid,stringbreak_hereparses").parse
  # # > ["a", "stupid", "string", "parses"]
  #
  # # Parsing works with simple quoted strings:
  # DefaultParser.new("a,\"more,interesting\",string").parse
  # # > ["a", "more,interesting", "string"]
  class DefaultParser < GenericParser
    class_attribute :delimiter

    def parse
      @tags = [].tap do |tag_list|
        tags.each do |tag|
          string = tag.to_s.dup

          extract_quoted_strings(string, tag_list, double_quote_pattern)
          extract_quoted_strings(string, tag_list, single_quote_pattern)

          # split the string by the delimiter
          # and add to the tag_list
          tag_list.concat(string.split(delimiter_regex))
        end
      end.flatten
    end

    def to_s
      tag_list = tags.frozen? ? tags.dup : tags

      d     = ActsAsTaggableOnMongoid::DefaultParser.delimiters.first
      regex = Regexp.new (Array.wrap(ActsAsTaggableOnMongoid::DefaultParser.delimiters) + %w[" ']).join("|")

      tag_list.map do |name|
        name.index(regex) ? "\"#{name}\"" : name
      end.join(d)
    end

    def self.delimiters
      Array.wrap(delimiter.presence || DEFAULT_DELIMITER)
    end

    private

    def extract_quoted_strings(string, tag_list, quote_pattern)
      string.gsub!(quote_pattern) do
        # Append the matched tag to the tag list
        tag_list << Regexp.last_match[2]
        # Return the matched delimiter ($3) to replace the matched items
        ""
      end
    end

    def delimiter
      # Parse the quoted tags
      d = self.class.delimiters
      # Separate multiple delimiters by bitwise operator
      d = d.join("|") if d.is_a?(Array)
      d
    end

    def delimiter_regex
      Regexp.new(delimiter)
    end

    # (             # Tag start delimiter ($1)
    # \A       |  # Either string start or
    # #{delimiter}        # a delimiter
    # )
    # \s*"          # quote (") optionally preceded by whitespace
    # (.*?)         # Tag ($2)
    # "\s*          # quote (") optionally followed by whitespace
    # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
    # #{delimiter}\s*  |  # Either a delimiter optionally followed by whitespace or
    # \z          # string end
    # )
    def double_quote_pattern
      /(\A|#{delimiter})\s*"(.*?)"\s*(?=#{delimiter}\s*|\z)/
    end

    # (             # Tag start delimiter ($1)
    # \A       |  # Either string start or
    # #{delimiter}        # a delimiter
    # )
    # \s*'          # quote (') optionally preceded by whitespace
    # (.*?)         # Tag ($2)
    # '\s*          # quote (') optionally followed by whitespace
    # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
    # #{delimiter}\s*  | d # Either a delimiter optionally followed by whitespace or
    # \z          # string end
    # )
    def single_quote_pattern
      /(\A|#{delimiter})\s*'(.*?)'\s*(?=#{delimiter}\s*|\z)/
    end
  end
end
