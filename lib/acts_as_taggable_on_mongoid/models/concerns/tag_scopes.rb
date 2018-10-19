module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagScopes
        extend ActiveSupport::Concern

        included do
          ### SCOPES:
          scope :most_used, ->(limit = 20) { order("taggings_count desc").limit(limit) }
          scope :least_used, ->(limit = 20) { order("taggings_count asc").limit(limit) }

          scope :named, ->(name) { where(name: as_8bit_ascii(name)) }
          scope :named_any, ->(*names) { where(:name.in => names.map { |name| as_8bit_ascii(name) }) }
          scope :named_like, ->(name) { where(name: /#{as_8bit_ascii(name)}/i) }
          scope :named_like_any, ->(*names) { where(:name.in => names.map { |name| /#{as_8bit_ascii(name)}/i }) }
          scope :for_context, ->(context) { where(context: context) }
          scope :for_taggable_class, ->(taggable_type) { where(taggable_type: taggable_type.name) }
          scope :for_tag, ->(tag_definition) { for_taggable_class(tag_definition.owner).for_context(tag_definition.tag_type) }
        end
      end
    end
  end
end
