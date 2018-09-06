# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing the actual tags assigned to a particular model object
    class Tagging
      include Mongoid::Document
      include Mongoid::Timestamps

      DEFAULT_CONTEXT = "tags"

      field :tag_name, type: String
      field :context, type: String

      belongs_to :tag, counter_cache: true, inverse_of: :taggings
      belongs_to :taggable, polymorphic: true
      # belongs_to :tagger, { polymorphic: true, optional: true }

      # If/when adding the concept of a tagger, this index will need to be changed.
      index({ taggable_id: 1, taggable_type: 1, context: 1, tag_name: 1 }, unique: true)
      index(tag_name: 1)
      index(tag_id: 1, tag_type: 1)

      # scope :owned_by, ->(owner) { where(tagger: owner) }
      # scope :not_owned, -> { where(tagger_id: nil, tagger_type: nil) }

      scope :by_contexts, ->(*contexts) { where(:context.in => Array.wrap(contexts.presence || DEFAULT_CONTEXT)) }
      scope :by_context, ->(context = DEFAULT_CONTEXT) { by_contexts(context.to_s) }
      scope :for_tag, ->(tag_definition) { where(taggable_type: tag_definition.owner.name).by_context(tag_definition.tag_type) }

      validates :tag_name, presence: true
      validates :context, presence: true
      validates :tag, presence: true
      validates :taggable, presence: true

      # validates :tag_id, uniqueness: {scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]}
      validates :tag_name, uniqueness: { scope: %i[taggable_type taggable_id context] }
      # validates :tag_id, uniqueness: {scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]}
      validates :tag_id, uniqueness: { scope: %i[taggable_type taggable_id context] }

      after_destroy :remove_unused_tags

      private

      def remove_unused_tags
        return nil unless taggable

        tag_definition = taggable.class.tag_definition(context)

        return unless tag_definition&.remove_unused_tags?

        tag.destroy if tag.reload.taggings_count.zero?
      end
    end
  end
end
