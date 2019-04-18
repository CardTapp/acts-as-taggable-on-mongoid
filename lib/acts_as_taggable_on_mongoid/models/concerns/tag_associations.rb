# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      module TagAssociations
        extend ActiveSupport::Concern

        included do
          ### ASSOCIATIONS:

          has_many :taggings, dependent: :destroy, class_name: "ActsAsTaggableOnMongoid::Models::Tagging"
        end
      end
    end
  end
end
