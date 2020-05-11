# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::ListTags do
  describe "tag_definition" do
    around(:each) do |test_proxy|
      test_proxy.run
    ensure
      TaggableModel.tag_types.delete(:alternate_tags)
    end

    it "returns the tag_defintion" do
      taggable = TaggableModel.new name: "Teth Adam", language_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"

      expect(taggable.tag_definition("languages").tag_type).to eq taggable.language_list.tag_definition.tag_type
      expect(taggable.tag_definition("languages")).not_to be_conflicts_with taggable.language_list.tag_definition
      expect(taggable.tag_types.count).to eq 5
      expect(TaggableModel.tag_types.count).to eq 5
    end

    it "creates a dynamic tag_defintion" do
      taggable = TaggableModel.new name: "Teth Adam", language_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"

      expect { expect(taggable.tag_definition("alternate_tags")).to be }.to change { taggable.tag_types.count }.by(1)

      expect(taggable.tag_types.count).to eq 6
      expect(TaggableModel.tag_types.count).to eq 6
    end
  end
end
