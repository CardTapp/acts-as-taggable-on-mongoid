# frozen_string_literal: true

# require "active_support/core_ext/module/delegation"

module ActsAsTaggableOnMongoid
  # A list of tags.  The TagList must be initialized with a tag definition so that it knows how to clean
  # the list properly and to convert the list to a string.
  #
  # All methods that add objects to the list (initialization, concat, etc.) optionally take an array of values including
  # options to parse the values and to optionally specifiy the parser to use.  If no parser is specified, then
  # parser for the tag_definition is used.
  #
  # If the input value(s) are to be parsed, then all values passed in are parsed.
  #
  # Examples:
  #   TagList.new(tag_definition, "value 1", "value 2")
  #   # > TagList<> ["value 1", "value 2"]
  #
  #   TagList.new(tag_definition, "value 1, value 2", parse: true)
  #   # > TagList<> ["value 1", "value 2"]
  #
  #   TagList.new(tag_definition, "value 1, value 2", "value 3, value 4", parse: true)
  #   # > TagList<> ["value 1", "value 2", "value 3", "value 4"]
  #
  #   TagList.new(tag_definition, "value 1, value 2", "value 3, value 4", parser: ActsAsTaggableOnMongoid::GenericParser)
  #   # > TagList<> ["value 1", "value 2", "value 3", "value 4"]

  # :reek:SubclassedFromCoreClass
  class TagList < Array
    # :reek:Attribute
    attr_accessor :taggable
    attr_reader :tag_definition

    def initialize(tag_definition, *args)
      @tag_definition = tag_definition

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
      TagList.new(tag_definition).add(*self).add(other)
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def concat(other_tag_list)
      notify_will_change

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
      remove_list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *names)

      notify_will_change

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
      tag_definition.parser.new(*self).to_s
    end

    def notify_will_change
      return unless taggable

      taggable.tag_list_on_changed tag_definition
    end

    # :reek:NilCheck
    def ==(other)
      if tag_definition.preserve_tag_order?
        super
      else
        self&.sort == other&.sort
      end
    end

    private

    # Convert everything to string, remove whitespace, duplicates, and blanks.
    def clean
      TagList.new(tag_definition).add(*self).clean!
    end

    def clean!
      reject!(&:blank?)

      map!(&:to_s)
      map!(&:strip)

      conditional_clean_rules
    end

    def conditional_clean_rules
      map! { |tag| tag.mb_chars.downcase.to_s } if tag_definition.force_lowercase?
      map!(&:parameterize) if tag_definition.force_parameterize?

      uniq!

      self
    end

    def extract_and_apply_options!(args)
      options = args.extract_options!
      options.assert_valid_keys :parse, :parser

      run_parser = options[:parser] || tag_definition.parser

      args.flatten!
      args.map! { |a| run_parser.new(a).parse } if options[:parse] || options[:parser]

      args.flatten!
    end
  end
end
