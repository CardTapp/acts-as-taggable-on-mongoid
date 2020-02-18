# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    # Overides of methods from Mongoid::Processing which process attributes for methods like
    # `assign_attributes`, `create`, `new`, and `update_attributes`
    #
    # The need for this override is because the base method splits the order that methods are
    # processed in to process relationships after processing other attributes.
    #
    # However, tag lists may rely upon values set in relationships - forcing us to process
    # tag lists AFTER relationships have been processed - preventing the need to order attributes
    # (which wouldn't help anyway because of the way process_attributes works.)
    #
    # ONLY taggings that have a default and which accept tagger values and which default the
    # tagger based on the taggable object could be affected by other attributes set at the same time
    # as the tag list.  Thus only those tag values are delayed until after all other attributes are set.
    module TaggerRelation
      def process_attributes(attrs = nil)
        update_attrs, defaulted_attrs = atom_attributes_without_defaults(attrs)

        super(update_attrs)

        defaulted_attrs.each do |key, value|
          public_send("#{key}=", value)
        end
      end

      private

      def atom_attributes_without_defaults(attrs)
        return_attributes    = {}
        defaulted_attributes = {}

        sanitize_for_mass_assignment(attrs)&.each do |key, value|
          tag_def = tag_types.detect { |_type, tag_definition| tag_definition.tag_list_name == key.to_s }&.last

          if tag_def&.tag_list_uses_default_tagger?
            defaulted_attributes[key] = value
          else
            return_attributes[key] = value
          end
        end

        [return_attributes, defaulted_attributes]
      end
    end
  end
end
