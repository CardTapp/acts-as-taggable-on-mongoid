# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Concerns::TagScopes do
  let(:taggable_type) { TaggableModel.name }
  let(:other_taggable_type) { TaggerTaggableModel.name }
  let(:tagger) { MyUser.create! name: "My User" }
  let(:other_tagger) { MyUser.create! name: "My User" }
  let!(:my_type_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "my name",
                                                 taggable_type: taggable_type,
                                                 context:       "tag")
  end
  let!(:my_type_second) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "my name",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag")
  end
  let!(:my_other_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "my name",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag")
  end
  let!(:my_other_tag_tagger) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "my name",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag",
                                                 tagger:        tagger)
  end
  let!(:my_type_second_other) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "my name",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag",
                                                 tagger:        other_tagger)
  end
  let!(:your_type_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "your name",
                                                 taggable_type: taggable_type,
                                                 context:       "tag")
  end
  let!(:your_type_second) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "your name",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag")
  end
  let!(:your_other_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "your name",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag")
  end
  let!(:your_other_tag_tagger) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "your name",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag",
                                                 tagger:        tagger)
  end
  let!(:your_type_second_other) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "your name",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag",
                                                 tagger:        other_tagger)
  end
  let!(:not_type_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "not to be found",
                                                 taggable_type: taggable_type,
                                                 context:       "tag")
  end
  let!(:not_type_second) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "not to be found",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag")
  end
  let!(:not_other_tag) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "not to be found",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag")
  end
  let!(:not_other_tag_tagger) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "not to be found",
                                                 taggable_type: other_taggable_type,
                                                 context:       "tag",
                                                 tagger:        tagger)
  end
  let!(:not_type_second_other) do
    ActsAsTaggableOnMongoid::Models::Tag.create!(name:          "not to be found",
                                                 taggable_type: taggable_type,
                                                 context:       "secondary_tag",
                                                 tagger:        other_tagger)
  end

  describe "named" do
    it "finds all tags with a given name" do
      tags = [my_type_tag,
              my_type_second,
              my_other_tag,
              my_other_tag_tagger,
              my_type_second_other]

      expect(ActsAsTaggableOnMongoid::Models::Tag.named("my name").to_a.sort).to eq tags.sort
    end
  end

  describe "named_any" do
    it "finds all tags with any given names" do
      tags = [my_type_tag,
              my_type_second,
              my_other_tag,
              my_other_tag_tagger,
              my_type_second_other,
              your_type_tag,
              your_type_second,
              your_other_tag,
              your_other_tag_tagger,
              your_type_second_other]

      expect(ActsAsTaggableOnMongoid::Models::Tag.named_any("my name", "your name").to_a.sort).to eq tags.sort
    end
  end

  describe "named_like" do
    it "finds all tags that match a regex" do
      tags = [my_type_tag,
              my_type_second,
              my_other_tag,
              my_other_tag_tagger,
              my_type_second_other,
              your_type_tag,
              your_type_second,
              your_other_tag,
              your_other_tag_tagger,
              your_type_second_other]

      expect(ActsAsTaggableOnMongoid::Models::Tag.named_like("name").to_a.sort).to eq tags.sort
    end
  end

  describe "named_like_any" do
    it "finds all tags that match a set of regexes" do
      tags = [not_type_tag,
              not_type_second,
              not_other_tag,
              not_other_tag_tagger,
              not_type_second_other,
              your_type_tag,
              your_type_second,
              your_other_tag,
              your_other_tag_tagger,
              your_type_second_other]

      expect(ActsAsTaggableOnMongoid::Models::Tag.named_like_any("not", "your").to_a.sort).to eq tags.sort
    end
  end

  describe "tagged_by" do
    it "finds all tags that are tagged by a tagger" do
      tags = [my_other_tag_tagger,
              your_other_tag_tagger,
              not_other_tag_tagger]

      expect(ActsAsTaggableOnMongoid::Models::Tag.tagged_by(tagger).to_a.sort).to eq tags.sort
    end

    it "finds all tags that are tagged by no tagger" do
      tags = [my_type_tag,
              my_type_second,
              my_other_tag,
              your_type_tag,
              your_type_second,
              your_other_tag,
              not_type_tag,
              not_type_second,
              not_other_tag]

      expect(ActsAsTaggableOnMongoid::Models::Tag.tagged_by(nil).to_a.sort).to eq tags.sort
    end
  end

  describe "for_tag_type" do
    it "finds all tags for a particular tag_type" do
      tags = [my_type_second,
              your_type_second,
              not_type_second,
              my_type_second_other,
              your_type_second_other,
              not_type_second_other]

      expect(ActsAsTaggableOnMongoid::Models::Tag.for_tag_type("secondary_tag").to_a.sort).to eq tags.sort
    end
  end

  describe "for_taggable_class" do
    it "finds all tags for a particular taggable class" do
      tags = [my_other_tag,
              my_other_tag_tagger,
              your_other_tag,
              your_other_tag_tagger,
              not_other_tag,
              not_other_tag_tagger]

      expect(ActsAsTaggableOnMongoid::Models::Tag.for_taggable_class(TaggerTaggableModel).to_a.sort).to eq tags.sort
    end
  end

  describe "for_tag" do
    it "finds all tags for a particular tag definition" do
      tags = [my_type_second,
              your_type_second,
              not_type_second,
              my_type_second_other,
              your_type_second_other,
              not_type_second_other]

      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "secondary_tag"

      expect(ActsAsTaggableOnMongoid::Models::Tag.for_tag(tag_definition).to_a.sort).to eq tags.sort
    end
  end
end
