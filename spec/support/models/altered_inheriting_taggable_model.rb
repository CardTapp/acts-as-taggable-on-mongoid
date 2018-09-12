# frozen_string_literal: true

# A test model used to show that inherited models can have additional tagged fields.
class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_on :parts
end
