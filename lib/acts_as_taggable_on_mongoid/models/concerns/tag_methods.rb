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
              array.concat find_or_create_all_with_like_by_name_owner tag_definition, tagger, tag_list
            end
          end

          def find_or_create_all_with_like_by_name_owner(tag_definition, owner, *list)
            list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, *Array.wrap(list).flatten)

            return [] if list.empty?

            list.map do |tag_name|
              tries ||= 3

              find_or_create_tag(tag_name, tag_definition, owner)
            rescue StandardError
              if (tries -= 1).positive?
                retry
              end

              raise
            end
          end

          # :reek:UtilityFunction
          def create_tag(tag_definition, owner, name)
            tag_definition.tags_table.create!(name:          name,
                                              owner:         owner,
                                              context:       tag_definition.tag_type,
                                              taggable_type: tag_definition.owner.name)
          end

          def as_8bit_ascii(string)
            string = string.to_s

            string.mb_chars
          end

          def find_or_create_tag(tag_name, tag_definition, owner)
            existing_tag = tag_definition.tags_table.for_tag(tag_definition).named(tag_name).owned_by(owner).first

            existing_tag || create_tag(tag_definition, owner, tag_name)
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

        private

        def tag_definition
          @tag_definition ||= taggable_type.constantize.tag_types[context]
        end
      end
    end
  end
end
