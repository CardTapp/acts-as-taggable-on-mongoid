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

    tagged.tag_list     = %w[tag_1 tag_2]
    tagged.not_tag_list = %w[tag_5 tag_6]
    tagged.save

    not_tagged.tag_list = %w[tag_3 tag_4]
    not_tagged.save

    tagged.reload

    expect(tagged.tag_list.sort).to eq %w[tag_1 tag_2].sort

    # expect(tagged.base_tags.sort).to eq %w[tag_1 tag_2 tag_3 tag_4 tag_5 tag_6].sort
    expect(tagged.taggings.to_a.sort).to eq ActsAsTaggableOnMongoid::Models::Tagging.where(taggable_id: tagged.id).to_a.sort

    tagged.tag_list = ["tag_2, tag_3, tag_9", parse: true]
    tagged.save

    expect(tagged.reload.tag_list).to eq %w[tag_2 tag_3 tag_9]
  end
end
