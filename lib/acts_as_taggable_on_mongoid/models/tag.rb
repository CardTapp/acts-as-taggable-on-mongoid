# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    # A class representing all tags that have ever been set on a model.
    class Tag
      include ActsAsTaggableOnMongoid::Models::Concerns::TagModel
    end
  end
end
