# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      # This module adds methods to a model for the tag_list fields for the Mongoid::Changable attributes of a field
      # including:
      #   * tag_list?
      #   * tag_list_change
      #   * tag_list_changed?
      #   * tag_list_will_change!
      #   * tag_list_changed_from_default?
      #   * tag_list_was
      #   * tagger_tag_list_was
      #   * tag_lists_was
      #   * reset_tag_list!
      #   * reset_tag_list_to_default!

      # :reek:FeatureEnvy
      # :reek:DuplicateMethodCall
      module Changeable
        def default_tagger_tag_list(taggable)
          list = ActsAsTaggableOnMongoid::TaggerTagList.new(self, nil)

          list_default              = default.dup
          list_default.taggable     = taggable
          list[list_default.tagger] = list_default

          list.taggable = taggable

          list
        end

        private

        def add_list_exists
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}?") do
              tag_list_cache_on(tag_definition).values.any?(&:present?)
            end
          end
        end

        def add_list_change
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_change") do
              get_tag_list_change(tag_definition)
            end
          end
        end

        def add_list_changed
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_changed?") do
              get_tag_list_changed(tag_definition)
            end
          end
        end

        def add_will_change
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_will_change!") do
              attribute_will_change! tag_list_name
            end
          end
        end

        def add_changed_from_default?
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_changed_from_default?") do
              changed_value = tag_definition.default_tagger_tag_list(self)
              current_value = tag_list_cache_on(tag_definition)

              !(changed_value <=> current_value)&.zero?
            end
          end
        end

        def add_get_was
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_was") do
              get_tag_list_was tag_definition
            end
          end
        end

        def add_get_lists_was
          tag_definition = self

          owner.taggable_mixin.module_eval do
            define_method("#{tag_definition.tagger_tag_lists_name}_was") do
              get_tag_lists_was(tag_definition)
            end
          end
        end

        def add_tagger_get_was
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("tagger_#{tag_list_name}_was") do |tagger|
              get_tagger_list_was(tag_definition, tagger)
            end
          end
        end

        def add_reset_list
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("reset_#{tag_list_name}!") do
              return unless public_send("#{tag_list_name}_changed?")

              tagger_tag_list_set(changed_attributes[tag_list_name].dup)
            end
          end
        end

        def add_reset_to_default
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("reset_#{tag_list_name}_to_default!") do
              tagger_tag_list_set(tag_definition.default_tagger_tag_list(self))
            end
          end
        end
      end
    end
  end
end
