# frozen_string_literal: true

# A class representing all tags that have ever been set on a model.
class OtherAltTag < AltTag
  def self.collection_name
    "acts_as_taggable_on_mongoid_models_other_alt_tags"
  end
end
