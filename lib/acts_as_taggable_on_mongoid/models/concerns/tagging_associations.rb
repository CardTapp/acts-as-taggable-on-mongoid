# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TaggingAssociations
        extend ActiveSupport::Concern

        included do
          belongs_to :tag, counter_cache: true, inverse_of: :taggings
          belongs_to :taggable, polymorphic: true
          # belongs_to :tagger, { polymorphic: true, optional: true }
        end
      end
    end
  end
end
