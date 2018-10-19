# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing the actual tags assigned to a particular model object
    class Tagging
      include ActsAsTaggableOnMongoid::Models::Concerns::TaggingModel
    end
  end
end
