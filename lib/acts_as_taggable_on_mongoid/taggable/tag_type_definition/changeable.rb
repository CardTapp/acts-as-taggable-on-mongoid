# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      module Changeable
        def add_list_exists
          tag_definition = self

          owner.taggable_mixin.module_eval do
            define_method("#{tag_definition.tag_list_name}?") do
              if send(tag_definition.tag_list_name)
                true
              else
                false
              end
            end
          end
        end

        def add_list_change
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_change") do
              return false unless changed_attributes.key?(tag_list_name)

              changed_value = changed_attributes[tag_list_name]
              current_value = send(tag_list_name)

              [changed_value, current_value] unless current_value == changed_value
            end
          end
        end

        def add_list_changed
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_changed?") do
              return false unless changed_attributes.key?(tag_list_name)

              changed_value = changed_attributes[tag_list_name]
              current_value = send(tag_list_name)

              current_value != changed_value
            end
          end
        end

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
              send "#{tag_list_name}_changed?"
            end
          end
        end

        def add_get_was
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("#{tag_list_name}_was") do
              if send "#{tag_list_name}_changed?"
                changed_attributes[tag_list_name]
              else
                send tag_list_name
              end
            end
          end
        end

        def add_reset_list
          tag_definition = self
          tag_list_name  = tag_definition.tag_list_name

          owner.taggable_mixin.module_eval do
            define_method("reset_#{tag_list_name}!") do
              send "#{tag_list_name}=", nil
            end

            alias_method "reset_#{tag_list_name}_to_default!".to_sym, "reset_#{tag_list_name}!".to_sym
          end
        end
      end
    end
  end
end
