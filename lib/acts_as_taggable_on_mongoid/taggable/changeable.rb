# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # Overides of methods from Mongoid::Changeable
    module Changeable
      def tag_list_on_changed(tag_definition)
        attribute_will_change!(tag_definition.tag_list_name)
      end

      def reload(*args)
        tag_types.each_value do |tag_definition|
          instance_variable_set tag_definition.all_tag_list_variable_name, nil
          instance_variable_set tag_definition.tag_list_variable_name, nil
        end

        super(*args)
      end

      def changed
        changed_values = super
        tag_list_names = tag_types.values.map(&:tag_list_name).map(&:to_s)

        changed_attributes.each_key do |key|
          next unless tag_list_names.include?(key.to_s)

          if public_send("#{key}_changed?")
            changed_values << key unless changed_values.include?(key)
          else
            changed_values.delete(key)
          end
        end

        changed_values
      end

      def changes
        changed_values = super

        tag_types.each_value do |tag_definition|
          tag_list_name = tag_definition.tag_list_name

          next unless changed_attributes.key? tag_list_name

          changed_values[tag_list_name] = [changed_attributes[tag_list_name], public_send(tag_list_name)]
        end

        changed_values
      end

      def setters
        setter_values  = super
        tag_list_names = tag_types.values.map(&:tag_list_name).map(&:to_s)

        setter_values.delete_if do |key, _value|
          tag_list_names.include?(key.to_s)
        end
      end

      private

      def attribute_will_change!(attribute_name)
        return super if tag_types.none? { |_tag_name, tag_definition| tag_definition.tag_list_name.to_s == attribute_name.to_s }

        return if changed_attributes.key?(attribute_name)

        changed_attributes[attribute_name] = public_send(attribute_name)&.dup
      end
    end
  end
end
