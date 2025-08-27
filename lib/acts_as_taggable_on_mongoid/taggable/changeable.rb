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

      # rubocop:disable Metrics/PerceivedComplexity
      def changed
        changed_values = super
        tag_list_names = tag_types.values.map(&:tag_list_name).map(&:to_s)

        changed_attributes.each_key do |key|
          next unless tag_list_names.include?(key.to_s)

          if field_changed?(key)
            changed_values << key unless changed_values.include?(key)
          else
            changed_values.delete(key)
          end
        end

        changed_values
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def changes
        changed_values = super

        tag_types.each_value do |tag_definition|
          tag_list_name = tag_definition.tag_list_name

          next unless field_changed?(tag_list_name)

          changed_values[tag_list_name] = public_send("#{tag_list_name}_change")
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
        tag_definition = tag_types.detect { |_tag_name, tag_def| tag_def.tag_list_name.to_s == attribute_name.to_s }&.last
        return super if tag_definition.blank?

        return if changed_attributes.key?(attribute_name)

        changed_attributes[attribute_name] = tag_list_cache_on(tag_definition)&.dup
      end

      def field_changed?(field_name)
        changed_method = "#{field_name}_previously_changed?"
        changed_method = "#{field_name}_changed?" unless respond_to?(changed_method)

        public_send(changed_method)
      rescue NoMethodError
        false
      end
    end
  end
end
