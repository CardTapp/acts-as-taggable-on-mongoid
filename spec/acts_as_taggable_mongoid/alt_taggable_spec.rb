# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable do
  it "does stuff" do
    tagged = AltTagged.create!(tag_list: ["fred", "george", "fred 1", "george 1"])

    tagged.tag_list = ["fred", "george", "fred 1", "george 1"]
    tagged.save!
    tagged.reload.tag_list
    expect(tagged.reload.tag_list).to eq ["fred", "george", "fred 1", "george 1"]

    tagged.tag_list.add "bob, marray", parse: true
    tagged.tag_list_changed?
    tagged.save!
    tagged.reload.tag_list
    expect(tagged.reload.tag_list).to eq ["fred", "george", "fred 1", "george 1", "bob", "marray"]

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
