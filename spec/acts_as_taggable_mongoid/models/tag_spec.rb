# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Tag do
  let(:tag) { ActsAsTaggableOnMongoid::Models::Tag.new name: "sample tag", context: "tags", taggable_type: TaggableModel.name }
  let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, :tags }
  let!(:user) { TaggableModel.create(name: "Pablo") }

  describe "named like any" do
    context "case insensitive collation without indexes or case sensitive collation with indexes" do
      before(:each) do
        ActsAsTaggableOnMongoid::Models::Tag.create!(name: "Awesome", context: "fake", taggable_type: "Taggable")
        ActsAsTaggableOnMongoid::Models::Tag.create!(name: "awesome", context: "fake", taggable_type: "Taggable")
        ActsAsTaggableOnMongoid::Models::Tag.create!(name: "epic", context: "fake", taggable_type: "Taggable")
      end

      it "should find both tags" do
        expect(ActsAsTaggableOnMongoid::Models::Tag.named_any("awesome", "epic").count).to eq(2)
      end
    end
  end

  describe "for context" do
    before(:each) do
      user.skill_list.add("ruby")
      user.tag_list.add("do_not_find")
      user.save!
    end

    it "should return tags that have been used in the given context" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.for_context("skills").pluck(:name)).to include("ruby")
    end

    it "should not return tags that have been used in other contexts" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.for_context("needs").pluck(:name)).to_not include("ruby")
    end
  end

  describe "find or create all by any name" do
    before(:each) do
      tag.name = "awesome"
      tag.save
    end

    it "should find by name" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "awesome")).to eq([tag])
    end

    it "should find by name case insensitive" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, :tags, force_lowercase: true

      expect(ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "AWESOME")).to eq([tag])
    end

    context "case sensitive" do
      it "should find by name case sensitive" do
        expect do
          ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "AWESOME")
        end.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(1)
      end
    end

    it "should create by name" do
      expect do
        ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "epic")
      end.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(1)
    end

    it "should find or create by name" do
      expect do
        expect(ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "awesome", "epic").map(&:name)).
            to eq(%w[awesome epic])
      end.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, [])).to be_empty
    end
  end

  it "should require a name" do
    tag.name = nil

    expect(tag).not_to be_valid

    expect(tag.errors[:name]).to eq(["can't be blank"])

    tag.name = "something"
    expect(tag).to be_valid

    expect(tag.errors[:name]).to be_empty
  end

  it "should equal a tag with the same name" do
    tag.name = "awesome"
    new_tag  = ActsAsTaggableOnMongoid::Models::Tag.new(name: "awesome")

    expect(new_tag).to eq(tag)
  end

  it "should equal an alt_tag with the same name" do
    tag.name = "awesome"
    new_tag  = AltTag.new(name: "awesome")

    expect(new_tag).not_to eq(tag)
  end

  it "should return its name when to_s is called" do
    tag.name = "cool"

    expect(tag.to_s).to eq("cool")
  end

  it "have named_scope named(something)" do
    tag.name = "cool"
    tag.save!

    expect(ActsAsTaggableOnMongoid::Models::Tag.named("cool")).to include(tag)
  end

  it "have named_scope named_like(something)" do
    tag.name = "cool"
    tag.save!

    another_tag = ActsAsTaggableOnMongoid::Models::Tag.create!(name: "coolip", context: "tags", taggable_type: TaggableModel.name)

    expect(ActsAsTaggableOnMongoid::Models::Tag.named_like("cool")).to include(tag, another_tag)
  end

  describe "escape wildcard symbols in like requests" do
    let!(:another_tag) { ActsAsTaggableOnMongoid::Models::Tag.create!(name: "coo%", context: "tags", taggable_type: TaggableModel.name) }
    let!(:another_tag2) { ActsAsTaggableOnMongoid::Models::Tag.create!(name: "coolish", context: "tags", taggable_type: TaggableModel.name) }

    before(:each) do
      tag.name = "cool"
      tag.save
    end

    it "return escaped result when \"%\" char present in tag" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.named_like("coo%")).to_not include(tag)
      expect(ActsAsTaggableOnMongoid::Models::Tag.named_like("coo%")).to include(another_tag)
    end
  end

  describe "when case sensitive" do
    before do
      tag.name = "awesome"
      tag.save!
    end

    it "should find by name" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "awesome")).to eq([tag])
    end

    it "should find by name case sensitively" do
      expect do
        ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, "AWESOME")
      end.to change(ActsAsTaggableOnMongoid::Models::Tag, :count)

      expect(ActsAsTaggableOnMongoid::Models::Tag.where(name: "AWESOME").count).to be_positive
    end

    it "should have a named_scope named(something) that matches exactly" do
      uppercase_tag = ActsAsTaggableOnMongoid::Models::Tag.create(name: "Cool")
      tag.name      = "cool"
      tag.save!

      expect(ActsAsTaggableOnMongoid::Models::Tag.named("cool")).to include(tag)
      expect(ActsAsTaggableOnMongoid::Models::Tag.named("cool")).to_not include(uppercase_tag)
    end

    it "should not change encoding" do
      name              = "\u3042"
      original_encoding = name.encoding
      record            = ActsAsTaggableOnMongoid::Models::Tag.find_or_create_all_with_like_by_name(tag_definition, name).first

      record.reload

      expect(record.name.encoding).to eq(original_encoding)
    end
  end

  describe "name uniqeness validation" do
    let(:duplicate_tag) { ActsAsTaggableOnMongoid::Models::Tag.new(name: "ror", context: "tags", taggable_type: TaggableModel.name) }

    before { ActsAsTaggableOnMongoid::Models::Tag.create(name: "ror", context: "tags", taggable_type: TaggableModel.name) }

    context "when do need unique names" do
      it "should run uniqueness validation" do
        expect(duplicate_tag).to_not be_valid
      end

      it "add error to name" do
        duplicate_tag.valid?

        expect(duplicate_tag.errors.size).to eq(1)
        expect(duplicate_tag.errors.messages[:name]).to include("is already taken")
      end
    end
  end

  describe "popular tags" do
    before do
      %w[sports rails linux tennis golden_syrup].each_with_index do |t, i|
        tag                = ActsAsTaggableOnMongoid::Models::Tag.new(name: t, context: "tags", taggable_type: TaggableModel.name)
        tag.taggings_count = i

        tag.save!
      end
    end

    it "should find the most popular tags" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.most_used(3).first.name).to eq("golden_syrup")
      expect(ActsAsTaggableOnMongoid::Models::Tag.most_used(3).to_a.length).to eq(3)
    end

    it "should find the least popular tags" do
      expect(ActsAsTaggableOnMongoid::Models::Tag.least_used(3).first.name).to eq("sports")
      expect(ActsAsTaggableOnMongoid::Models::Tag.least_used(3).to_a.length).to eq(3)
    end
  end
end
