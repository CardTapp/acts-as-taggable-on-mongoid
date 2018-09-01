# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  ##
  # Returns a new Array using the given tag string.
  #
  # Example:
  #   tag_list = ActsAsTaggableOnMongoid::DefaultParser.parse("One , Two,  Three")
  #   tag_list # ["One", "Two", "Three"]
  class DefaultParser < GenericParser
    class_attribute :delimiter

    def parse
      return tags if tags.is_a?(Array)

      string = tags.to_s.dup

      # string = string.join(ActsAsTaggableOn.glue) if string.respond_to?(:join)
      [].tap do |tag_list|
        extract_quoted_strings(string, tag_list, double_quote_pattern)
        extract_quoted_strings(string, tag_list, single_quote_pattern)

        # split the string by the delimiter
        # and add to the tag_list
        tag_list.concat(string.split(delimiter_regex))
      end
    end

    def self.stringify_tag_list(*tag_list)
      tags = tag_list.frozen? ? tag_list.dup : tag_list

      d     = delimiters.first
      regex = Regexp.new delimiters.join("|")

      tags.map do |name|
        name.index(regex) ? "\"#{name}\"" : name
      end.join(d)
    end

    def self.delimiters
      Array.wrap(delimiter.presence || ",")
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
