# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing the actual tags assigned to a particular model object
    class Tagging
      include Mongoid::Document
      include Mongoid::Timestamps

      DEFAULT_CONTEXT = 'tags'

      field :tag_name, type: String
      field :context, type: String

      belongs_to :taggable, polymorphic: true
      # belongs_to :tagger, {polymorphic: true}.tap {|o| o.merge!(optional: true) }

      # If/when adding the concept of a tagger, this index will need to be changed.
      index({ taggable_id: 1, taggable_type: 1, context: 1, tag_name: 1 }, unique: true)
      index(tag_name: 1)

      def tag
        return nil unless taggable

        @tag ||= taggable.class.tag_definition(context).tags_table.where(taggable_type: taggable_type, context: context, name: tag_name).first
      end


      # scope :owned_by, ->(owner) { where(tagger: owner) }
      # scope :not_owned, -> { where(tagger_id: nil, tagger_type: nil) }

      scope :by_contexts, ->(*contexts) { where(:context.in => Array.wrap(contexts.presence || DEFAULT_CONTEXT)) }
      scope :by_context, ->(context = DEFAULT_CONTEXT) { by_contexts(context.to_s) }

      validates_presence_of :tag_name
      validates_presence_of :context
      # validates_presence_of :tag_id
      validates_presence_of :taggable

      # validates_uniqueness_of :tag_id, scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]
      validates_uniqueness_of :tag_name, scope: [:taggable_type, :taggable_id, :context]

      after_create :increment_counts
      after_destroy :decrement_counts
      after_destroy :remove_unused_tags

      private

      def increment_counts
        return nil unless taggable && tag

        taggable.class.tag_definition(context).tags_table.find(tag.id).inc taggings_count: 1
      end

      def decrement_counts
        return nil unless taggable && tag

        taggable.class.tag_definition(context).tags_table.find(tag.id).dec taggings_count: 1
      end

      def remove_unused_tags
        return nil unless taggable

        tag_definition = taggable.class.tag_definition(context)

        if tag_definition.remove_unused_tags?
          if tag_definition.tags_counter?
            tag.destroy if tag.reload.taggings_count.zero?
          else
            tag.destroy if tag.reload.taggings.count.zero?
          end
        end
      end
    end
  end
end
