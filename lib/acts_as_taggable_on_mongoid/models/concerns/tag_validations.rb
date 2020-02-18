# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagValidations
        extend ActiveSupport::Concern

        included do
          ### VALIDATIONS:

          validates :name, presence: true
          validates :context, presence: true
          validates :taggable_type, presence: true
          validates :name, uniqueness: { scope: %i[context taggable_type owner] }
        end
      end
    end
  end
end
