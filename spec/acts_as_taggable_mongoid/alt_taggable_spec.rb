# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable do
  it "does stuff" do
    tagged = AltTagged.create!(tag_list: ["fred", "george", "fred 1", "george 1"])

    tagged.tag_list = ["fred", "george", "fred 1", "george 1"]
    # tagged.setters
    tagged.save!
    tagged.reload.tag_list
    expect(tagged.reload.tag_list).to eq ["fred", "george", "fred 1", "george 1"]

    # tagged.tag_list.add("tag_3,tag_6", parse: true)
    tagged.alt_tagging_other_tag_list = ["fred", "george", "fred 2", "george 2"]
    tagged.save!
    tagged.reload.alt_tagging_other_tag_list
    expect(tagged.reload.alt_tagging_other_tag_list).to eq ["fred", "george", "fred 2", "george 2"]

    tagged.other_tagging_alt_tag_list = ["fred", "george", "fred 3", "george 3"]
    tagged.save!
    tagged.reload.other_tagging_alt_tag_list
    expect(tagged.reload.other_tagging_alt_tag_list).to eq ["fred", "george", "fred 3", "george 3"]

    tagged.other_tagging_other_tag_list = ["fred", "george", "fred 4", "george 4"]
    tagged.save!
    tagged.reload.other_tagging_other_tag_list
    expect(tagged.reload.other_tagging_other_tag_list).to eq ["fred", "george", "fred 4", "george 4"]
  end
end

# override changes to include the current tag_list values
# add tag_list_chnaged? method
# add tag_list_cahnge method
# [17] = {Symbol} setters
#
# [17] = {Symbol} changed
# [18] = {Symbol} changes
# [19] = {Symbol} changed_attributes
# [20] = {Symbol} changed?
# [21] = {Symbol} remove_change
# [22] = {Symbol} move_changes
# [23] = {Symbol} children_changed?
# [24] = {Symbol} previous_changes
#
# [0] = {Symbol} string_field
# [1] = {Symbol} string_field_before_type_cast
# [2] = {Symbol} string_field=
# [3] = {Symbol} string_field?
# [4] = {Symbol} string_field_change
# [5] = {Symbol} string_field_changed?
# [6] = {Symbol} string_field_will_change!
# [7] = {Symbol} string_field_changed_from_default?
# [8] = {Symbol} string_field_was
# [9] = {Symbol} reset_string_field!
# [10] = {Symbol} reset_string_field_to_default!