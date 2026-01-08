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

        original_value = build_original_tag_list(tag_definition)

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

      def changed
        changed_values = super

        tag_list_changes.each_key do |tag_list_name|
          next unless public_send("#{tag_list_name}_changed?")

          changed_values << tag_list_name unless changed_values.include?(tag_list_name)
        end

        changed_values
      end

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

      def build_original_tag_list(tag_definition)
        default_tagger = resolve_default_tagger(tag_definition)

        return cached_original_tag_list(tag_definition, default_tagger) if tag_list_cache_set_on(tag_definition)
        return new_record_original_tag_list(tag_definition, default_tagger) if new_record?

        tagger_tag_list_from_taggings(tag_definition, all_tags_on(tag_definition))
      end

      def resolve_default_tagger(tag_definition)
        default_tagger = tag_definition.tag_list_default_tagger(self)
        return default_tagger unless default_tagger.nil? && tag_definition.tagger?

        tag_definition.default_tagger(self)
      end

      def cached_original_tag_list(tag_definition, _default_tagger)
        cached_list = tag_list_cache_on(tag_definition)
        return tag_definition.default_tagger_tag_list(self) if new_record? && cached_list.blank?

        cached_list&.dup
      end

      def new_record_original_tag_list(tag_definition, default_tagger)
        default_value = tag_definition.default_tagger_tag_list(self)
        list_default = tag_definition.taggable_default(self)

        if list_default && default_tagger
          default_value[default_tagger] = list_default.dup
        end

        default_value
      end

      def attribute_will_change!(attribute_name)
        tag_definition = tag_types.detect { |_tag_name, tag_def| tag_def.tag_list_name.to_s == attribute_name.to_s }&.last
        return super if tag_definition.blank?

        store_tag_list_change(tag_definition)

        super
      end
    end
  end
end
