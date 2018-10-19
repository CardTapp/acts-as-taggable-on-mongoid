module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagFields
        extend ActiveSupport::Concern

        included do
          include Mongoid::Document
          include Mongoid::Timestamps

          field :name, type: String
          field :taggings_count, type: Integer, default: 0
          field :context, type: String
          field :taggable_type, type: String

          # field :type, type: String

          index({ name: 1, taggable_type: 1, context: 1 }, unique: true)
        end
      end
    end
  end
end
