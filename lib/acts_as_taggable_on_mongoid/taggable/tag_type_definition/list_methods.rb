# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      # This module extracts out the methods used to add list methods to the taggable object
      module ListMethods
        def add_list_getter
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method(tag_list_name) do
              tag_list_on tag_definition
            end

            alias_method "#{tag_list_name}_before_type_cast".to_sym, tag_list_name.to_sym
          end
        end

        def add_list_setter
          tag_definition = self

          owner.taggable_mixin.module_eval do
            define_method("#{tag_definition.tag_list_name}=") do |new_tags|
              set_tag_list(tag_definition, new_tags)
            end
          end
        end

        def add_all_list_getter
          tag_definition = self

          owner.taggable_mixin.module_eval do
            define_method(tag_definition.all_tag_list_name) do
              all_tags_list_on tag_definition
            end
          end
        end

        def add_tagger_tag_list
          tag_definition = self
          tag_list_name  = tag_definition.tagger_tag_list_name

          owner.taggable_mixin.module_eval do
            define_method(tag_list_name) do |owner|
              return nil unless tag_definition.tagger?

              tag_list_cache_on(tag_definition)[owner]
            end
          end
        end

        def add_tagger_tag_lists
          tag_definition = self
          tag_list_name  = tag_definition.tagger_tag_lists_name

          owner.taggable_mixin.module_eval do
            define_method(tag_list_name) do
              tag_list_cache_on(tag_definition)
            end
          end
        end
      end
    end
  end
end
