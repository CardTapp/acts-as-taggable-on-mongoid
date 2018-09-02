# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable do
  it "adds a tag_list method" do
    tagged = Tagged.new

    expect(tagged.tag_list).to be_blank
  end

  it "reads taggings" do
    not_tagged = Tagged.create

    tagged = Tagged.create

    taggings = [ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_1", context: "tags", taggable: tagged),
                ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_2", context: "tags", taggable: tagged),
                ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_5", context: "not_tags", taggable: tagged),
                ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_6", context: "not_tags", taggable: tagged)]

    ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_3", context: "tags", taggable: not_tagged)
    ActsAsTaggableOnMongoid::Models::Tagging.create(tag_name: "tag_4", context: "tags", taggable: not_tagged)

    expect(tagged.tag_list.sort).to eq %w[tag_1 tag_2].sort

    # expect(tagged.base_tags.sort).to eq %w[tag_1 tag_2 tag_3 tag_4 tag_5 tag_6].sort
    expect(tagged.taggings.to_a.sort).to eq taggings.sort

    tagged.tag_list = ["tag_2, tag_3, tag_9", parse: true]
    tagged.save

    expect(tagged.reload.tag_list).to eq %w(tag_2 tag_3 tag_9)
  end
end
