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
  # Options:
  #   parse   - True/False - indicates if all of the strings that are passed in are to be parsed
  #             to split them into an array of strings.
  #             Please note - if the passed in value is an array of strings, every string in the array
  #             will be parsed.  If it is a single array, then just that string is parsed.
  #   parser  - Class - A class that is used to parse the passed in strings.
  #             If this parameter is supplied, parse is assumed to be truthy even if it is not passed in.
  #   tagger  - object - An object that is to be used as the Tagger for the Taggable object.
  #             This parameter is ignored if the tag does not support Taggers.
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

  # :reek:MissingSafeMethod
  # :reek:SubclassedFromCoreClass
  class TagList < Array
    # :reek:Attribute
    attr_accessor :taggable
    attr_reader :tag_definition

    def initialize(tag_definition, *args)
      @tag_definition = tag_definition

      add(*args)
    end

    class << self
      def new_taggable_list(tag_definition, taggable)
        list = ActsAsTaggableOnMongoid::TagList.new(tag_definition)

        list.taggable = taggable

        list
      end
    end

    def dup
      list          = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *self)
      list.tagger   = instance_variable_get(:@tagger) if instance_variable_defined?(:@tagger)
      list.taggable = taggable

      list
    end

    def tagger=(value)
      return unless tag_definition.tagger?

      instance_variable_set(:@tagger, value)
    end

    def tagger
      return nil unless tag_definition.tagger?
      return tag_definition.default_tagger(taggable) unless instance_variable_defined?(:@tagger)

      tagger = instance_variable_get(:@tagger)
      tagger = taggable&.public_send(tagger) if tagger.is_a?(Symbol)

      instance_variable_set(:@tagger, tagger)
    end

    ##
    # Add tags to the tag_list. Duplicate or blank tags will be ignored.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.add("Fun", "Happy")
    #   tag_list.add("Fun, Happy", :parse => true)
    def add(*names)
      names = extract_and_apply_options!(names)
      concat(names)
      clean!

      self
    end

    ##
    # Replaces the tags with the tags passed in.
    #
    # Example:
    #   tag_list.set("Fun", "Happy")
    #   tag_list.set("Fun, Happy", :parse => true)
    def set(*names)
      clear
      add(*names)
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
      dup.add(other)
    end

    # Removal --- Returns a new tag list built by removing the
    # passed in tag list to produce a third tag list.
    def -(other)
      dup.remove(other)
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def concat(other_tag_list)
      notify_will_change

      super(other_tag_list).send(:clean!)

      self
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def clear
      notify_will_change

      super

      self
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def silent_concat(other_tag_list)
      temp_taggable = taggable
      self.taggable = nil

      concat(other_tag_list)

      self.taggable = temp_taggable

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

    # :reek:ManualDispatch
    def ==(other)
      if tag_definition.preserve_tag_order?
        super
      elsif other.respond_to?(:sort)
        self&.sort == other.sort
      end
    end

    def add_tagging(tagging)
      orig_taggable = taggable
      @taggable     = nil

      begin
        tag = tagging.tag_name

        self << tag unless include?(tag)
      ensure
        @taggable = orig_taggable
      end
    end

    private

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
      dup_args = args.dup
      options  = dup_args.extract_options!.dup

      options.assert_valid_keys :parse, :parser, :tagger

      instance_variable_set(:@tagger, options[:tagger]) if options.key?(:tagger) && tag_definition.tagger?

      parse_args_values(dup_args, options)
    end

    def parse_args_values(dup_args, options)
      options_parser = options[:parser]
      run_parser     = options_parser || tag_definition.parser

      dup_args.flatten!
      dup_args.map! { |argument| run_parser.new(argument).parse } if options[:parse] || options_parser

      dup_args.flatten!
      dup_args
    end
  end
end
