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

      def taggings
        return nil unless taggable_type.present?

        taggable_type.constantize.tag_definition(context).taggings_table.where(taggable_type: taggable_type, context: context, tag_name: name)
      end

      ### VALIDATIONS:

      validates_presence_of :name
      validates_presence_of :context
      validates_presence_of :taggable_type

      ### SCOPES:
      scope :most_used, ->(limit = 20) { order('taggings_count desc').limit(limit) }
      scope :least_used, ->(limit = 20) { order('taggings_count asc').limit(limit) }

      scope :named, ->(name) { where(name: as_8bit_ascii(name)) }
      scope :named_any, ->(*names) { where(:name.in => names.map { |name| as_8bit_ascii(name) }) }
      scope :for_context, ->(context) { where(context: context) }
      scope :for_taggable_class, ->(taggable_type) { where(taggable_type: taggable_type.name) }
      scope :for_tag, ->(tag_definition) { for_taggable_class(tag_definition.owner).for_context(tag_definition.tag_type) }

      ### CLASS METHODS:

      class << self
        def find_or_create_all_with_like_by_name(tag_definition, *list)
          list = TagList.new(tag_definition, *Array.wrap(list).flatten)

          return [] if list.empty?

          list.map do |tag_name|
            begin
              tries ||= 3

              existing_tag = for_tag(tag_definition).named(tag_name).first

              existing_tag || create_tag(tag_definition, tag_name)
            rescue Mongoid::Errors::Validations
              if (tries -= 1).positive?
                retry
              end

              raise ActsAsTaggableOnMongoid::Errors::DuplicateTagError.new("'#{tag_name}' has already been taken")
            end
          end
        end

        private

        def create_tag(tag_definition, name)
          create(name:          name,
                 context:       tag_definition.tag_type,
                 taggable_type: tag_definition.owner.name)
        end

        def as_8bit_ascii(string)
          if defined?(Encoding)
            string.to_s.dup.force_encoding('BINARY')
          else
            string.to_s.mb_chars
          end
        end
      end

      ### INSTANCE METHODS:

      def ==(object)
        super || (object.is_a?(Tag) && name == object.name)
      end

      def to_s
        name
      end
    end
  end
end
