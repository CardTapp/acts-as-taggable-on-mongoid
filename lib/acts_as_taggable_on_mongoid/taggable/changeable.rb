# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # Overides of methods from Mongoid::Changeable
    module Changeable
      def tag_list_on_changed(tag_definition)
        attribute_will_change!(tag_definition.tag_list_name)
      end

      def reload(*args)
        self.class.tag_types.each_value do |tag_definition|
          instance_variable_set tag_definition.all_tag_list_variable_name, nil
          instance_variable_set tag_definition.tag_list_variable_name, nil
        end

        super(*args)
      end

      def changed
        changed_values = super

        changed_attributes.each_key do |key|
          next if changed_values.include?(key)

          changed_values << key if self.class.tag_types.any? { |_tag_name, tag_definition| tag_definition.tag_list_name.to_s == key.to_s }
        end

        changed_values
      end

      def changes
        changed_values = super

        self.class.tag_types.each_value do |tag_definition|
          tag_list_name = tag_definition.tag_list_name

          next unless changed_attributes.key? tag_list_name

          changed_values[tag_list_name] = [changed_attributes[tag_list_name], send(tag_list_name)]
        end

        changed_values
      end

      def setters
        setter_values = super

        setter_values.delete_if do |key, _value|
          self.class.tag_types.any? { |_tag_name, tag_definition| tag_definition.tag_list_name.to_s == key.to_s }
        end
      end

      private

      def attribute_will_change!(attribute_name)
        return super if self.class.tag_types.none? { |_tag_name, tag_definition| tag_definition.tag_list_name.to_s == attribute_name.to_s }

        return if changed_attributes.key?(attribute_name)

        changed_attributes[attribute_name] = send(attribute_name)&.dup
      end
    end
  end
end
