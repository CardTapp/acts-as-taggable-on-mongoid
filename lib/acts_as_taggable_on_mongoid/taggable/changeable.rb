# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # Overides of methods from Mongoid::Changeable
    module Changeable
      def self.included(base)
        base.after_save :clear_tag_list_changes
      end

      def tag_list_changes
        @tag_list_changes ||= {}
      end

      def clear_tag_list_changes
        @tag_list_changes = {}
      end

      def store_tag_list_change(tag_definition)
        tag_list_name = tag_definition.tag_list_name

        return if tag_list_changes.key?(tag_list_name)

        default_tagger = tag_definition.tag_list_default_tagger(self)
        default_tagger ||= tag_definition.default_tagger(self) if tag_definition.tagger?

        original_value = if tag_list_cache_set_on(tag_definition)
                           cached_list = tag_list_cache_on(tag_definition)

                           if new_record? && cached_list.blank?
                             tag_definition.default_tagger_tag_list(self)
                           else
                             cached_list&.dup
                           end
                         elsif new_record?
                           default_value = tag_definition.default_tagger_tag_list(self)

                           list_default = tag_definition.taggable_default(self)
                           default_value[default_tagger] = list_default.dup if list_default && default_tagger

                           default_value
                         else
                           # build from persisted taggings when no cache is set
                           tagger_tag_list_from_taggings(tag_definition, all_tags_on(tag_definition))
                         end

        tag_list_changes[tag_list_name] = original_value
      end

      def tag_list_on_changed(tag_definition)
        attribute_will_change!(tag_definition.tag_list_name)
      end

      def reload(*args)
        tag_types.each_value do |tag_definition|
          instance_variable_set tag_definition.all_tag_list_variable_name, nil
          instance_variable_set tag_definition.tag_list_variable_name, nil
        end

        clear_tag_list_changes

        super(*args)
      end

      # rubocop:disable Metrics/PerceivedComplexity
      def changed
        changed_values = super

        tag_list_changes.each_key do |tag_list_name|
          next unless public_send("#{tag_list_name}_changed?")

          changed_values << tag_list_name unless changed_values.include?(tag_list_name)
        end

        changed_values
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def changes
        changed_values = super

        tag_types.each_value do |tag_definition|
          tag_list_name = tag_definition.tag_list_name

          next unless public_send("#{tag_list_name}_changed?")

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

        store_tag_list_change(tag_definition)

        super
      end
    end
  end
end
