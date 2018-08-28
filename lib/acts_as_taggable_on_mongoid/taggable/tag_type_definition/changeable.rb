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
      #   * reset_tag_list!
      #   * reset_tag_list_to_default!
      module Changeable
        def add_list_exists
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}?") do
              public_send(tag_list_name).present?
            end
          end
        end

        def add_list_change
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_change") do
              return nil unless public_send("#{tag_list_name}_changed?")

              changed_value = public_send("#{tag_list_name}_was")
              current_value = public_send(tag_list_name)

              [changed_value, current_value] unless current_value == changed_value
            end
          end
        end

        # rubocop:disable Metrics/AbcSize

        def add_list_changed
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_changed?") do
              return false unless changed_attributes.key?(tag_list_name)

              changed_value = new_record? ? tag_definition.default : changed_attributes[tag_list_name]
              current_value = public_send(tag_list_name)

              unless tag_definition.preserve_tag_order?
                changed_value.sort!
                current_value.sort!
              end

              current_value != changed_value
            end
          end
        end

        # rubocop:enable Metrics/AbcSize

        def add_will_change
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_will_change!") do
              attribute_wil_change! tag_list_name
            end
          end
        end

        def add_changed_from_default?
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_changed_from_default?") do
              changed_value = tag_definition.default
              current_value = public_send(tag_list_name)

              unless tag_definition.preserve_tag_order?
                changed_value.sort!
                current_value.sort!
              end

              current_value != changed_value
            end
          end
        end

        def add_get_was
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_was") do
              return tag_definition.default if new_record?

              if public_send "#{tag_list_name}_changed?"
                changed_attributes[tag_list_name]
              else
                public_send tag_list_name
              end
            end
          end
        end

        def add_reset_list
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("reset_#{tag_list_name}!") do
              public_send "#{tag_list_name}=", public_send("#{tag_list_name}_was")
            end
          end
        end

        def add_reset_to_default
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("reset_#{tag_list_name}_to_default!") do
              public_send "#{tag_list_name}=", tag_definition.default
            end
          end
        end
      end
    end
  end
end
