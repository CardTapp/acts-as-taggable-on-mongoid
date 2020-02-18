# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # TagTypeDefinition represents the definition for a aingle tag_type in a model.
    #
    # The options passed into a tag_type defined through acts_as_taggable* method are stored in the tag definition
    # which then drives the creation of the relations and methods that are added to the model.
    #
    # The TagTypeDefinition mirrors the Configuraiton attributes and defaults any value that isn't passed in
    # to the value in the Configuration (ActsAsTaggableOnMongoid.configuration)
    class TagTypeDefinition
      attr_reader :owner,
                  :tag_type

      include ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::ListMethods
      include ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Attributes
      include ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Names
      include ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Changeable

      def initialize(owner, tag_type, options = {})
        options = extract_tag_definition_options(options)

        default_option = options.delete(:default)

        save_options(options)

        self.default_value = default_option

        @owner    = owner
        @tag_type = tag_type
      end

      def self.copy_from(klass, tag_definition)
        dup_hash = %i[parser
                      preserve_tag_order
                      cached_in_model
                      force_lowercase
                      force_parameterize
                      remove_unused_tags
                      tags_table
                      taggings_table].each_with_object({}) { |dup_key, opts_hash| opts_hash[dup_key] = tag_definition.public_send(dup_key) }

        dup_hash[:default] = tag_definition.default.dup

        ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new klass,
                                                                 tag_definition.tag_type,
                                                                 dup_hash
      end

      def conflicts_with?(tag_definition)
        %i[parser preserve_tag_order force_lowercase force_parameterize taggings_table].any? do |setting_name|
          public_send(setting_name) != tag_definition.public_send(setting_name)
        end
      end

      # :reek:FeatureEnvy

      # I've defined the parser as being required to return an array of strings.
      # This parse function will take that array and make it a TagList which will then use the tag_definition
      # to apply the rules to that list (like case sensitivity and parameterization, etc.) to get the final
      # list.
      def parse(*tag_list)
        dup_tag_list     = tag_list.dup
        options          = dup_tag_list.extract_options!.dup
        options[:parser] ||= parser if options[:parse] || options.key?(:parser)

        ActsAsTaggableOnMongoid::TagList.new(self, *dup_tag_list, options)
      end

      def taggings_order
        @taggings_order = if preserve_tag_order?
                            [:created_at.asc, :id.asc]
                          else
                            []
                          end
      end

      def define_base_relations
        tag_definition = self

        add_base_tags_method

        owner.class_eval do
          taggings_name = tag_definition.taggings_name

          break if relations[taggings_name.to_s]

          has_many taggings_name,
                   as:           :taggable,
                   dependent:    :destroy,
                   class_name:   tag_definition.taggings_table.name,
                   after_add:    :dirtify_tag_list,
                   after_remove: :dirtify_tag_list
        end
      end

      # Mongoid does not allow the `through` option for relations, so we de-normalize data and manually add the methods we need
      # for through like functionality.
      def add_base_tags_method
        tag_definition   = self
        base_tags_method = tag_definition.base_tags_method

        owner.taggable_mixin.module_eval do
          break if methods.include?(base_tags_method)

          define_method base_tags_method do
            tag_definition.tags_table.where(taggable_type: tag_definition.owner.name)
          end
        end
      end

      def define_relations
        # Relations cannot be added for the tags and taggings like they are in ActiveRecord because
        # Mongoid does not allow for a scope like ActiveRecord does.
        #
        # Therefore the relation like actions will have to be defined separately ourselves.  If any
        # relation actions are missed, we'll just have to fix it here when we find them.
        # (This is far from ideal, but it is the only way to work around the issue at this time.)

        add_context_taggings_method
        add_context_tags_method
      end

      def add_context_taggings_method
        tag_definition = self
        taggings_name  = tag_definition.taggings_name

        owner.taggable_mixin.module_eval do
          define_method "#{tag_definition.single_tag_type}_#{taggings_name}".to_sym do
            public_send(taggings_name).
                order_by(*tag_definition.taggings_order).
                for_tag(tag_definition)
          end
        end
      end

      def add_context_tags_method
        tag_definition = self

        owner.taggable_mixin.module_eval do
          define_method tag_definition.tag_type.to_sym do
            public_send("#{tag_definition.single_tag_type}_#{tag_definition.taggings_name}").map(&:tag)
          end
        end
      end

      def add_tag_list
        add_list_getter
        add_list_setter
        add_tagger_tag_list
        add_tagger_tag_lists
        add_all_list_getter
        add_list_exists
        add_list_change
        add_list_changed
        add_changed_from_default?
        add_will_change
        add_get_was
        add_get_lists_was
        add_tagger_get_was
        add_reset_list
        add_reset_to_default
      end

      private

      def extract_tag_definition_options(options)
        options = options.dup

        options.assert_valid_keys(:parser,
                                  :preserve_tag_order,
                                  :cached_in_model,
                                  :force_lowercase,
                                  :force_parameterize,
                                  :remove_unused_tags,
                                  :tags_table,
                                  :taggings_table,
                                  :default,
                                  :tagger)
        options
      end

      def save_options(options)
        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end
    end
  end
end
