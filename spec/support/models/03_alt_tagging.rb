# frozen_string_literal: true

# A class representing the actual tags assigned to a particular model object
class AltTagging < ActsAsTaggableOnMongoid::Models::Tagging
  def self.collection_name
    'acts_as_taggable_on_mongoid_models_alt_taggings'
  end

  belongs_to :tag, polymorphic: true, counter_cache: true, inverse_of: :taggings
end
