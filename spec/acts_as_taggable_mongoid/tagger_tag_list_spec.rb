# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::TaggerTagList do
  let(:tagger) { MyUser.create! name: "My User" }
  let(:other_tagger) { MyUser.create! name: "Other User" }
  let(:language_user) { MyUser.find_or_create_by! name: "Language User" }
  let(:taggable) { TaggerTaggableModel.new name: "taggable", my_user: tagger }
  let(:tag_definition) { taggable.tag_types[:languages] }
  let(:tagger_tag_list) { ActsAsTaggableOnMongoid::TaggerTagList.new(tag_definition, taggable) }

  it "returns a TagList" do
    tag_list = tagger_tag_list[nil]

    expect(tag_list).to be_a ActsAsTaggableOnMongoid::TagList
    expect(tag_list.tag_definition).to eq tag_definition
    expect(tag_list.taggable).to eq taggable
    expect(tag_list.tagger).to be_nil
  end

  it "sets the TagList tagger" do
    tag_list = tagger_tag_list[tagger]

    expect(tag_list).to be_a ActsAsTaggableOnMongoid::TagList
    expect(tag_list.tag_definition).to eq tag_definition
    expect(tag_list.taggable).to eq taggable
    expect(tag_list.tagger).to eq tagger
  end

  describe "flatten" do
    it "creates a list with the default owner for the taggable" do
      tag_list = tagger_tag_list[nil]
      tag_list.concat %w[Test tag list]
      tag_list = tagger_tag_list[tagger]
      tag_list.concat %w[Tagger tag list]

      tag_list = tagger_tag_list.flatten
      expect(tag_list.tagger).to eq language_user
    end

    it "removes duplicates between owners" do
      tag_list = tagger_tag_list[nil]
      tag_list.concat %w[Test tag list]
      tag_list = tagger_tag_list[tagger]
      tag_list.concat %w[Tagger tag list]

      tag_list = tagger_tag_list.flatten
      expect(tag_list.sort).to eq %w[Test tag list Tagger].sort
    end
  end

  describe "<=>" do
    let(:tag_list) { ActsAsTaggableOnMongoid::TagList.new_taggable_list(tag_definition, taggable) }
    let(:compare_tag_list) { ActsAsTaggableOnMongoid::TaggerTagList.new(tag_definition, taggable) }
    let(:tag_definition) { taggable.tag_types[:preserved] }

    it "returns nil for random classes" do
      expect(tagger_tag_list <=> tagger).to be_nil
    end

    context "TagList" do
      before(:each) do
        tagger_tag_list[tagger].concat %w[This is a tag list of values]
        tag_list.concat %w[This is a tag list of values]
      end

      it "returns 0 if the lists are equal" do
        expect(tagger_tag_list <=> tag_list).to eq 0
      end

      it "returns -1 if the list is empty" do
        tagger_tag_list.clear

        expect(tagger_tag_list <=> tag_list).to eq(-1)
      end

      it "returns 1 if the list has multiple taggers" do
        tagger_tag_list[language_user].concat %w[Another list]

        expect(tagger_tag_list <=> tag_list).to eq 1
      end

      it "returns 1 or -1 if the taggers are not equal" do
        tag_list.tagger = language_user

        expect(tagger_tag_list <=> tag_list).not_to be_zero
      end

      it "returns 1 or -1 if the taggable are not equal" do
        tag_list.taggable = TaggerTaggableModel.new name: "other taggable", my_user: tagger

        expect(tagger_tag_list <=> tag_list).not_to be_zero
      end

      it "returns equality based on preserve tag order" do
        tag_list.clear
        tag_list.concat %w[is a tag list of values This]

        expect(tagger_tag_list <=> tag_list).not_to be_zero
      end

      context "do not preserve tag order" do
        let(:tag_definition) { taggable.tag_types[:skills] }

        it "is equal if different order" do
          tag_list.clear
          tag_list.concat %w[is a tag list of values This]

          expect(tagger_tag_list <=> tag_list).to be_zero
        end
      end
    end

    context "TaggerTagList" do
      before(:each) do
        tagger_tag_list[tagger].concat %w[This is a tag list of values]
        compare_tag_list[tagger].concat %w[This is a tag list of values]
        tagger_tag_list[other_tagger].concat %w[Another list of tag values]
        compare_tag_list[other_tagger].concat %w[Another list of tag values]
      end

      it "is equal" do
        expect(tagger_tag_list <=> compare_tag_list).to be_zero
      end

      it "is -1 if 1 less tagger" do
        compare_tag_list.delete(tagger)

        expect(tagger_tag_list <=> compare_tag_list).to eq 1
      end

      it "is 1 if more taggers" do
        compare_tag_list[nil].concat %w[No Onwer List]

        expect(tagger_tag_list <=> compare_tag_list).to eq(-1)
      end

      it "returns 1 or -1 if the tagables are not equal" do
        compare_tag_list.taggable = TaggerTaggableModel.new name: "other taggable", my_user: tagger

        expect(tagger_tag_list <=> compare_tag_list).not_to be_zero
      end

      it "returns 1 or -1 if any list differs by tag order" do
        compare_tag_list[other_tagger].clear
        compare_tag_list[other_tagger].concat %w[list of tag values Another]

        expect(tagger_tag_list <=> compare_tag_list).not_to be_zero
      end

      context "do not preserve tag order" do
        let(:tag_definition) { taggable.tag_types[:skills] }

        it "is equal if different order" do
          compare_tag_list[other_tagger].clear
          compare_tag_list[other_tagger].concat %w[list of tag values Another]

          expect(tagger_tag_list <=> compare_tag_list).to be_zero
        end
      end
    end
  end

  describe "dup" do
    it "duplicates non-blank lists" do
      tagger_tag_list[tagger].concat %w[List to be duplicated]
      tagger_tag_list[nil].concat []
      tagger_tag_list[other_tagger].concat %w[Other list]

      dup_list = tagger_tag_list.dup

      tagger_tag_list[tagger].concat %w[new elements]

      expect(dup_list.keys).to eq [tagger, other_tagger]
      expect(dup_list[tagger]).to eq %w[List to be duplicated]
      expect(dup_list[other_tagger]).to eq %w[Other list]
    end
  end

  describe "compact" do
    it "creates a duplicate with taggers with empty lists removed" do
      tagger_tag_list[nil]          = nil
      tagger_tag_list[tagger]       = "A, list"
      tagger_tag_list[other_tagger] = nil

      expect(tagger_tag_list.length).to eq 3
      expect(tagger_tag_list.compact.length).to eq 1
      expect(tagger_tag_list.length).to eq 3
    end
  end

  describe "compact!" do
    it "removes all taggers with empty lists" do
      tagger_tag_list[nil]          = nil
      tagger_tag_list[tagger]       = "A, list"
      tagger_tag_list[other_tagger] = nil

      expect(tagger_tag_list.length).to eq 3
      tagger_tag_list.compact!
      expect(tagger_tag_list.length).to eq 1
    end
  end

  describe "[]=" do
    it "leaves other tagger lists alone" do
      tagger_tag_list[nil]          = %w[List One]
      tagger_tag_list[tagger]       = "A, list"
      tagger_tag_list[other_tagger] = %w[This is it]

      expect(tagger_tag_list[nil]).to eq %w[List One]
      expect(tagger_tag_list[tagger]).to eq %w[A list]
      expect(tagger_tag_list[other_tagger]).to eq %w[This is it]
    end

    it "replaces existing values for a tagger" do
      tagger_tag_list[nil]          = %w[List One]
      tagger_tag_list[tagger]       = "A, list"
      tagger_tag_list[other_tagger] = %w[This is it]

      expect(tagger_tag_list[nil]).to eq %w[List One]
      expect(tagger_tag_list[tagger]).to eq %w[A list]
      expect(tagger_tag_list[other_tagger]).to eq %w[This is it]

      tagger_tag_list[other_tagger] = %w[List One]
      tagger_tag_list[nil]          = "A, list"
      tagger_tag_list[tagger]       = %w[This is it]

      expect(tagger_tag_list[other_tagger]).to eq %w[List One]
      expect(tagger_tag_list[nil]).to eq %w[A list]
      expect(tagger_tag_list[tagger]).to eq %w[This is it]
    end

    it "parses values by default" do
      tagger_tag_list[nil] = "A, list"

      expect(tagger_tag_list[nil]).to eq %w[A list]
    end

    it "does not parse values if told not to" do
      tagger_tag_list[nil] = ["A, list", parse: false]

      expect(tagger_tag_list[nil]).to eq ["A, list"]
    end

    it "uses a custom parser" do
      tagger_tag_list[nil] = ["\"A, list\"", parser: ActsAsTaggableOnMongoid::GenericParser]

      expect(tagger_tag_list[nil]).to eq ["\"A", "list\""]
    end
  end

  describe "blank?" do
    it "returns true if all lists are blank" do
      tagger_tag_list[nil]          = nil
      tagger_tag_list[tagger]       = nil
      tagger_tag_list[other_tagger] = nil

      expect(tagger_tag_list).to be_blank
    end

    it "returns true if all lists are blank" do
      tagger_tag_list[nil]          = nil
      tagger_tag_list[tagger]       = nil
      tagger_tag_list[other_tagger] = %w[A list here]

      expect(tagger_tag_list).not_to be_blank
    end
  end
end
