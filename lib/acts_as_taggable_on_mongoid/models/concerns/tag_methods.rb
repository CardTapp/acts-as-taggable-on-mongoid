module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagMethods
        extend ActiveSupport::Concern

        ### CLASS METHODS:

        class_methods do
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
end
