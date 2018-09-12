# frozen_string_literal: true

# Make sure that all indexes are created.
[ActsAsTaggableOnMongoid::Models::Tag,
 ActsAsTaggableOnMongoid::Models::Tagging,
 AltTagged,
 Company,
 OrderedTaggableModel,
 TaggableLowerModel,
 TaggableModel,
 Tagged,
 UntaggableModel].each do |model|
  model.remove_indexes
  raise "cannot create indexes" unless model.create_indexes
end
