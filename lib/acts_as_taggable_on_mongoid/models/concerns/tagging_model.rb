module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # This module includes all methods and defintions needed/used by a Tagging model.
      #
      # Tagging model definitions are done via including this or the sub-modules so that
      # the definitions of the core attributes for a Tagging model can be defined in each
      # class separately.
      #
      # The primary reason for doing this is validations, which call the superclass validations
      # for classes that inherit causing problems with independent inherted classes.
      module TaggingModel
        extend ActiveSupport::Concern

        included do
          include ActsAsTaggableOnMongoid::Models::Concerns::TaggingFields
          include ActsAsTaggableOnMongoid::Models::Concerns::TaggingMethods
          include ActsAsTaggableOnMongoid::Models::Concerns::TaggingAssociations
          include ActsAsTaggableOnMongoid::Models::Concerns::TaggingValidations
          include ActsAsTaggableOnMongoid::Models::Concerns::TaggingScopes
        end
      end
    end
  end
end
