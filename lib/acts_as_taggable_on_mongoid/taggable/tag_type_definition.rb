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
                  :preserve_tag_order,
                  :cached_in_model,
                  :index_cache,
                  :tag_type

      def initialize(owner, tag_type, options = {})
        options.assert_valid_keys(:parser,
                                  :preserve_tag_order,
                                  :cached_in_model,
                                  :index_cache,
                                  :force_lowercase,
                                  :force_parameterize,
                                  :remove_unused_tags,
                                  :tags_table,
                                  :taggings_table,
                                  :tags_counter)

        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        @owner    = owner
        @tag_type = tag_type
      end

      def parser
        @parser || ActsAsTaggableOnMongoid.default_parser
      end

      def tags_table
        @tags_table || ActsAsTaggableOnMongoid.tags_table
      end

      def taggings_table
        @taggings_table || ActsAsTaggableOnMongoid.taggings_table
      end

      def tags_counter
        if defined?(@tags_counter)
          @tags_counter
        else
          ActsAsTaggableOnMongoid.configuration.tags_counter?
        end
      end

      def force_lowercase
        if defined?(@force_lowercase)
          @force_lowercase
        else
          ActsAsTaggableOnMongoid.configuration.force_lowercase?
        end
      end

      def force_parameterize
        if defined?(@force_parameterize)
          @force_parameterize
        else
          ActsAsTaggableOnMongoid.configuration.force_parameterize?
        end
      end

      def remove_unused_tags
        if defined?(@remove_unused_tags)
          @remove_unused_tags
        else
          ActsAsTaggableOnMongoid.configuration.remove_unused_tags?
        end
      end

      # rubocop:disable Layout/SpaceAroundOperators

      # I've defined the parser as being required to return an array of strings.
      # This parse function will take that array and make it a TagList which will then use the tag_definition
      # to apply the rules to that list (like case sensitivity and parameterization, etc.) to get the final
      # list.
      def parse(*tag_list)
        options          = tag_list.extract_options!
        options[:parser] ||= parser if options.key?(:parse) || options.key?(:parser)

        ActsAsTaggableOnMongoid::TagList.new(self, *tag_list, options)
      end

      # rubocop:enable Layout/SpaceAroundOperators

      def tag_list_name
        @tag_list_name ||= "#{single_tag_type}_list"
      end

      def tag_list_variable_name
        @tag_list_variable_name ||= "@#{tag_list_name}"
      end

      def all_tag_list_name
        @all_tag_list_name ||= "all_#{single_tag_type}_list"
      end

      def all_tag_list_variable_name
        @all_tag_list_variable_name ||= "@#{tag_list_name}"
      end

      def save_tags_method
        @save_tags_method ||= "save_#{single_tag_type}_list"
      end

      def single_tag_type
        @single_tag_type ||= tag_type.to_s.singularize
      end

      def base_tags_method
        @base_tags_method ||= "base_#{tags_table.name.demodulize.underscore.downcase.pluralize}".to_sym
      end

      def taggings_name
        @taggings_name ||= taggings_table.name.demodulize.underscore.downcase.pluralize.to_sym
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
        tag_definition = self

        owner.taggable_mixin.module_eval do
          break if methods.include?(tag_definition.base_tags_method)

          define_method tag_definition.base_tags_method do
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

        owner.taggable_mixin.module_eval do
          define_method "#{tag_definition.single_tag_type}_taggings".to_sym do
            send(tag_definition.taggings_name).
                order_by(*tag_definition.taggings_order).
                for_tag(tag_definition)
          end
        end
      end

      def add_context_tags_method
        tag_definition = self

        owner.taggable_mixin.module_eval do
          define_method tag_definition.tag_type.to_sym do
            send(base_tags_method).
                order_by(*tag_definition.taggings_order).
                for_tag(tag_definition)
          end
        end
      end

      def add_tag_list
        add_list_getter
        add_list_setter
        add_all_list_getter
      end

      def add_list_getter
        tag_definition = self

        owner.taggable_mixin.module_eval do
          define_method(tag_definition.tag_list_name) do
            tag_list_on tag_definition
          end
        end
      end

      # TODO: Refactor this so that dirty attributes are set properly.
      def add_list_setter
        tag_definition = self

        owner.taggable_mixin.module_eval do
          tag_list_name = tag_definition.tag_list_name

          define_method("#{tag_list_name}=") do |new_tags|
            parsed_new_list = tag_definition.parse(*Array.wrap(new_tags))

            current_tag_list = send(tag_list_name)

            if (tag_definition.preserve_tag_order? && parsed_new_list != current_tag_list) ||
                parsed_new_list.sort != current_tag_list.sort
              changed_attributes[tag_list_name] = current_tag_list
            end

            tag_list_set(parsed_new_list)
          end
        end
      end

      def add_all_list_getter
        tag_definition = self

        owner.taggable_mixin.module_eval do
          define_method(tag_definition.all_tag_list_name) do
            all_tag_list_on tag_definition
          end
        end
      end

      alias preserve_tag_order? preserve_tag_order
      alias cached_in_model? cached_in_model
      alias index_cache? index_cache
      alias tags_counter? tags_counter
      alias force_lowercase? force_lowercase
      alias force_parameterize? force_parameterize
      alias remove_unused_tags? remove_unused_tags
    end
  end
end
