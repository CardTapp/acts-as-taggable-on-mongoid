# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagModel
        extend ActiveSupport::Concern

        included do
          include ActsAsTaggableOnMongoid::Models::Concerns::TagFields
          include ActsAsTaggableOnMongoid::Models::Concerns::TagMethods
          include ActsAsTaggableOnMongoid::Models::Concerns::TagAssociations
          include ActsAsTaggableOnMongoid::Models::Concerns::TagValidations
          include ActsAsTaggableOnMongoid::Models::Concerns::TagScopes
          include ActsAsTaggableOnMongoid::Models::Concerns::TagHooks
        end
      end
    end
  end
end
