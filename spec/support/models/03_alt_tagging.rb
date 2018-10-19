# frozen_string_literal: true

# A class representing the actual tags assigned to a particular model object
class AltTagging
  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingModel

  belongs_to :tag, polymorphic: true, counter_cache: true, inverse_of: :taggings
end
