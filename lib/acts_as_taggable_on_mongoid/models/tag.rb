# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing all tags that have ever been set on a model.
    class Tag
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      field :taggings_count, type: Integer, default: 0
      field :context, type: String
      field :taggable_type, type: String

      # field :type, type: String

      index({ name: 1, taggable_type: 1, context: 1 }, unique: true)

      ### ASSOCIATIONS:

      has_many :taggings, dependent: :destroy, class_name: "ActsAsTaggableOnMongoid::Models::Tagging"

      ### VALIDATIONS:

      validates :name, presence: true
      validates :context, presence: true
      validates :taggable_type, presence: true
      validates :name, uniqueness: { scope: %i[context taggable_type] }

      ### SCOPES:
      scope :most_used, ->(limit = 20) { order("taggings_count desc").limit(limit) }
      scope :least_used, ->(limit = 20) { order("taggings_count asc").limit(limit) }

      scope :named, ->(name) { where(name: as_8bit_ascii(name)) }
      scope :named_any, ->(*names) { where(:name.in => names.map { |name| as_8bit_ascii(name) }) }
      scope :named_like, ->(name) { where(name: /#{as_8bit_ascii(name)}/i) }
      scope :named_like_any, ->(*names) { where(:name.in => names.map { |name| /#{as_8bit_ascii(name)}/i }) }
      scope :for_context, ->(context) { where(context: context) }
      scope :for_taggable_class, ->(taggable_type) { where(taggable_type: taggable_type.name) }
      scope :for_tag, ->(tag_definition) { for_taggable_class(tag_definition.owner).for_context(tag_definition.tag_type) }

      ### CLASS METHODS:

      class << self
        def find_or_create_all_with_like_by_name(tag_definition, *list)
          list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *Array.wrap(list).flatten)

          return [] if list.empty?

          list.map do |tag_name|
            begin
              tries ||= 3

              existing_tag = tag_definition.tags_table.for_tag(tag_definition).named(tag_name).first

              existing_tag || create_tag(tag_definition, tag_name)
            rescue Mongoid::Errors::Validations
              # :nocov:
              if (tries -= 1).positive?
                retry
              end

              raise ActsAsTaggableOnMongoid::Errors::DuplicateTagError.new, "'#{tag_name}' has already been taken"
              # :nocov:
            end
          end
        end

        private

        def create_tag(tag_definition, name)
          tag_definition.tags_table.create(name:          name,
                                           context:       tag_definition.tag_type,
                                           taggable_type: tag_definition.owner.name)
        end

        def as_8bit_ascii(string)
          string = string.to_s
          if defined?(Encoding)
            string.dup.force_encoding("BINARY")
          else
            # :nocov:
            string.mb_chars
            # :nocov:
          end
        end
      end

      ### INSTANCE METHODS:

      def ==(other)
        super || (other.class == self.class &&
            name == other.name &&
            context == other.context &&
            taggable_type == other.taggable_type)
      end

      def to_s
        name
      end
    end
  end
end
