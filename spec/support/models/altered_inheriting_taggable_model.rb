# frozen_string_literal: true

class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_on :parts
end
