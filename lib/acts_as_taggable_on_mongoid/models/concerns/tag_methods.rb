# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagMethods
        extend ActiveSupport::Concern

        ### CLASS METHODS:

        # rubocop:disable Metrics/BlockLength
        class_methods do
          def find_or_create_tagger_list_with_like_by_name(tag_definition, tagger_list)
            tagger_list.each_with_object([]) do |(tagger, tag_list), array|
              array.concat find_or_create_all_with_like_by_name_tagger tag_definition, tagger, tag_list
            end
          end

          def find_or_create_all_with_like_by_name_tagger(tag_definition, tagger, *list)
            list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *Array.wrap(list).flatten)

            return [] if list.empty?

            list.map do |tag_name|
              begin
                tries ||= 3

                find_or_create_tag(tag_name, tag_definition, tagger)
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

          def create_tag(tag_definition, tagger, name)
            tag_definition.tags_table.create!(name:          name,
                                              tagger:        tagger,
                                              context:       tag_definition.tag_type,
                                              taggable_type: tag_definition.owner.name)
          end

          def as_8bit_ascii(string)
            string = string.to_s

            string.mb_chars
          end

          private

          def find_or_create_tag(tag_name, tag_definition, tagger)
            existing_tag = tag_definition.tags_table.for_tag(tag_definition).named(tag_name).tagged_by(tagger).first

            existing_tag || create_tag(tag_definition, tagger, tag_name)
          end
        end

        # rubocop:enable Metrics/BlockLength

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
