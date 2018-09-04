# frozen_string_literal: true

# A class representing the actual tags assigned to a particular model object
class OtherTagging < AltTagging
  def self.collection_name
    'acts_as_taggable_on_mongoid_models_other_taggings'
  end
end
