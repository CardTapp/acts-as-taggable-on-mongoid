# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing the actual tags assigned to a particular model object
    class Tagging
      include Mongoid::Document
      include Mongoid::Timestamps

      field :tag_name, type: String
      field :context, type: String

      belongs_to :taggable, polymorphic: true

      # If/when adding the concept of a tagger, this index will need to be changed.
      index({ taggable_id: 1, taggable_type: 1, context: 1, tag_name: 1 }, unique: true)
      index(tag_name: 1)

      def tag
        return nil unless taggable

        @tag ||= taggable.tag_definition(context).tags_table.where(taggable_type: taggable_type, context: context, name: tag_name).first
      end
    end
  end
end
