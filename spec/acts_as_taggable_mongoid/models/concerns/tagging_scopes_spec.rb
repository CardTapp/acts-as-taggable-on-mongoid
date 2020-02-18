# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Concerns::TagScopes do
  let(:taggables) { Array.new(3) { TaggableModel.create! name: "Taggable" } }
  let(:other_taggables) { Array.new(3) { TaggerTaggableModel.create! name: "TaggerTaggableModel", my_user: tagger } }
  let(:tagger) { MyUser.create! name: "My User" }
  let(:other_tagger) { MyUser.create! name: "My User" }
  let!(:fake_tags) do
    Array.new(5) do |index|
      ActsAsTaggableOnMongoid::Models::Tag.create!(name: "my name #{index}", taggable_type: taggables[0].class.name, context: "tag")
    end
  end

  # <type>_<taggable>_<tagger>
  let(:tag_basic_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "tag_basic_none",
                                                     taggable: taggables[0],
                                                     context:  "tag"
  end
  let(:tag_other_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "tag_other_none",
                                                     taggable: other_taggables[0],
                                                     context:  "tag"
  end
  let(:tag_basic_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "tag_basic_tagger",
                                                     taggable:   taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "tag"
  end
  let(:tag_other_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "tag_other_tagger",
                                                     taggable:   other_taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "tag"
  end
  let(:tag_basic_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "tag_basic_other",
                                                     taggable:   taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "tag"
  end
  let(:tag_other_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "tag_other_other",
                                                     taggable:   other_taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "tag"
  end
  let(:secondary_basic_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "secondary_basic_none",
                                                     taggable: taggables[0],
                                                     context:  "secondary_tag"
  end
  let(:secondary_other_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "secondary_other_none",
                                                     taggable: other_taggables[0],
                                                     context:  "secondary_tag"
  end
  let(:secondary_basic_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "secondary_basic_tagger",
                                                     taggable:   taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "secondary_tag"
  end
  let(:secondary_other_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "secondary_other_tagger",
                                                     taggable:   other_taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "secondary_tag"
  end
  let(:secondary_basic_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "secondary_basic_other",
                                                     taggable:   taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "secondary_tag"
  end
  let(:secondary_other_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "secondary_other_other",
                                                     taggable:   other_taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "secondary_tag"
  end
  let(:third_basic_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "third_basic_none",
                                                     taggable: taggables[0],
                                                     context:  "third_tag"
  end
  let(:third_other_none) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:      fake_tags.sample,
                                                     tag_name: "third_other_none",
                                                     taggable: other_taggables[0],
                                                     context:  "third_tag"
  end
  let(:third_basic_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "third_basic_tagger",
                                                     taggable:   taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "third_tag"
  end
  let(:third_other_tagger) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "third_other_tagger",
                                                     taggable:   other_taggables[1],
                                                     tag_tagger: tagger,
                                                     context:    "third_tag"
  end
  let(:third_basic_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "third_basic_other",
                                                     taggable:   taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "third_tag"
  end
  let(:third_other_other) do
    ActsAsTaggableOnMongoid::Models::Tagging.create! tag:        fake_tags.sample,
                                                     tag_name:   "third_other_other",
                                                     taggable:   other_taggables[2],
                                                     tag_tagger: other_tagger,
                                                     context:    "third_tag"
  end

  describe "by_tag_types" do
    it "finds all tags for a set of tag types" do
      taggings = [tag_basic_none,
                  tag_other_none,
                  tag_basic_tagger,
                  tag_other_tagger,
                  tag_basic_other,
                  tag_other_other,
                  third_basic_none,
                  third_other_none,
                  third_basic_tagger,
                  third_other_tagger,
                  third_basic_other,
                  third_other_other]

      expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_types("third_tag", "tag").to_a.sort).to eq taggings.sort
    end
  end

  describe "by_tag_type" do
    it "finds all tags for a particular tag_type" do
      taggings = [secondary_basic_none,
                  secondary_other_none,
                  secondary_basic_tagger,
                  secondary_other_tagger,
                  secondary_basic_other,
                  secondary_other_other]

      expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_type("secondary_tag").to_a.sort).to eq taggings.sort
    end
  end

  describe "tagged_by" do
    it "finds all tags that are tagged by a tagger" do
      taggings = [tag_basic_other,
                  tag_other_other,
                  secondary_basic_other,
                  secondary_other_other,
                  third_basic_other,
                  third_other_other]

      expect(ActsAsTaggableOnMongoid::Models::Tagging.tagged_by(other_tagger).to_a.sort).to eq taggings.sort
    end

    it "finds all tags that are tagged by no tagger" do
      taggings = [tag_basic_none,
                  tag_other_none,
                  secondary_basic_none,
                  secondary_other_none,
                  third_basic_none,
                  third_other_none]

      expect(ActsAsTaggableOnMongoid::Models::Tagging.tagged_by(nil).to_a.sort).to eq taggings.sort
    end
  end

  describe "for_tag" do
    it "finds all tags for a particular tag definition" do
      taggings = [secondary_basic_none,
                  secondary_basic_tagger,
                  secondary_basic_other]

      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "secondary_tag"

      expect(ActsAsTaggableOnMongoid::Models::Tagging.for_tag(tag_definition).to_a.sort).to eq taggings.sort
    end
  end
end
