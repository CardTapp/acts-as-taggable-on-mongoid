# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::Core do
  describe "save_tags" do
    it "doesn't save to the database until save is called" do
      taggable = TaggableModel.new name: "Teth Adam", language_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"

      expect(ActsAsTaggableOnMongoid::Models::Tagging.count).to be_zero

      taggable.save!

      expect(ActsAsTaggableOnMongoid::Models::Tagging.count).to eq 6
    end
  end

  describe "dirtify_tag_list" do
    it "can add taggings through the taggings relation" do
      taggable = TaggableModel.create! name: "Teth Adam"
      tag      = ActsAsTaggableOnMongoid::Models::Tag.create!(name: "Set", context: "languages", taggable_type: TaggableModel.name)

      taggable.taggings.create!(tag_name: "Set", context: "languages", tag: tag)

      tags = taggable.reload.language_list

      expect(tags).to eq ["Set"]
    end
  end
end
