# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Errors
    # Error raised if a Tag already exists but cannot be found appropriately when trying to create new tags.
    class DuplicateTagError < StandardError
    end
  end
end
