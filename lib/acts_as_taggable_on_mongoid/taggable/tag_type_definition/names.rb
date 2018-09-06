# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TagTypeDefinition
      # Methods for the TagTypeDefinition class which provide the names for important/commonly used methods that will
      # be defined/added for a tag when it is added to a model.
      module Names
        def tag_list_name
          @tag_list_name ||= "#{single_tag_type}_list"
        end

        def tag_list_variable_name
          @tag_list_variable_name ||= "@#{tag_list_name}"
        end

        def all_tag_list_name
          @all_tag_list_name ||= "all_#{tag_type}_list"
        end

        def all_tag_list_variable_name
          @all_tag_list_variable_name ||= "@#{tag_list_name}"
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
      end
    end
  end
end
