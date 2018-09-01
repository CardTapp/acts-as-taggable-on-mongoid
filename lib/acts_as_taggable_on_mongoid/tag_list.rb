# frozen_string_literal: true

# require "active_support/core_ext/module/delegation"

module ActsAsTaggableOnMongoid
  class TagList < Array
    # attr_accessor :owner
    attr_accessor :parser
    attr_reader :tag_type_definition

    def initialize(tag_type_definition, *args)
      @tag_type_definition = tag_type_definition

      add(*args)
    end

    ##
    # Add tags to the tag_list. Duplicate or blank tags will be ignored.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.add("Fun", "Happy")
    #   tag_list.add("Fun, Happy", :parse => true)
    def add(*names)
      extract_and_apply_options!(names)
      concat(names)
      clean!

      self
    end

    # Append---Add the tag to the tag_list. This
    # expression returns the tag_list itself, so several appends
    # may be chained together.
    def <<(obj)
      add(obj)
    end

    # Concatenation --- Returns a new tag list built by concatenating the
    # two tag lists together to produce a third tag list.
    def +(other)
      TagList.new(tag_type_definition).add(*self).add(other)
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def concat(other_tag_list)
      super(other_tag_list).send(:clean!)
      self
    end

    ##
    # Remove specific tags from the tag_list.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.remove("Sad", "Lonely")
    #   tag_list.remove("Sad, Lonely", :parse => true)
    def remove(*names)
      remove_list = ActsAsTaggableOnMongoid::TagList.new(tag_type_definition, *names)

      delete_if { |name| remove_list.include?(name) }

      self
    end

    ##
    # Transform the tag_list into a tag string suitable for editing in a form.
    # The tags are joined with <tt>TagList.delimiter</tt> and quoted if necessary.
    #
    # Example:
    #   tag_list = TagList.new("Round", "Square,Cube")
    #   tag_list.to_s # 'Round, "Square,Cube"'
    def to_s
      run_parser = parser || tag_type_definition.parser

      run_parser.stringify_tag_list(*self)
    end

    private

    # Convert everything to string, remove whitespace, duplicates, and blanks.
    def clean!
      reject!(&:blank?)

      map!(&:to_s)
      map!(&:strip)

      conditional_clean_rules!
    end

    def conditional_clean_rules!
      map! { |tag| tag.mb_chars.downcase.to_s } if tag_type_definition.force_lowercase?
      map!(&:parameterize) if tag_type_definition.force_parameterize?

      tag_type_definition.strict_case_match ? uniq! : uniq!(&:downcase)

      self
    end

    def extract_and_apply_options!(args)
      options = args.extract_options!
      options.assert_valid_keys :parse, :parser

      run_parser = options[:parser] || parser || tag_type_definition.parser

      args.flatten!
      args.map! { |a| run_parser.new(a).parse } if options[:parse] || options[:parser]

      args.flatten!
    end
  end
end
