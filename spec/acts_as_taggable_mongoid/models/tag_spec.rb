# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Tag do
  let(:tag) { ActsAsTaggableOnMongoid::Models::Tag.new name: "sample tag", context: "tags", taggable_type: TaggableModel.name }
  let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, :tags }
  let!(:user) { TaggableModel.create(name: "Pablo") }

  context "ActsAsTaggableOn" do
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
      new_tag  = ActsAsTaggableOnMongoid::Models::Tag.new(name: "awesome", context: tag.context, taggable_type: tag.taggable_type)

      expect(new_tag).to eq(tag)
    end

    it "should not equal an alt_tag with the same name" do
      tag.name = "awesome"
      new_tag  = AltTag.new(name: "awesome")

      expect(new_tag).not_to eq(tag)
    end

    it "should return its name when to_s is called" do
      tag.name = "cool"

      expect(tag.to_s).to eq("cool")
    end

    it "have named_scope named(something)" do
      ActsAsTaggableOnMongoid::Models::Tag.create! name: "cool", context: "language", taggable_type: TaggableModel.name

      tag.name = "cool"
      tag.save!

      expect(ActsAsTaggableOnMongoid::Models::Tag.named("cool")).to include(tag)
      expect(ActsAsTaggableOnMongoid::Models::Tag.named("cool").count).to eq 2
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
        index = -1
        %w[sports rails linux tennis golden_syrup].each do |tag|
          index += 1

          tag                = ActsAsTaggableOnMongoid::Models::Tag.new(name: tag, context: "tags", taggable_type: TaggableModel.name)
          tag.taggings_count = index

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

  describe "unique index" do
    it "has a unique index" do
      tag.save!

      duplicate_tag    = ActsAsTaggableOnMongoid::Models::Tag.new(tag.attributes)
      duplicate_tag.id = BSON::ObjectId.new
      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors.messages[:name]).to include("is already taken")

      expect { duplicate_tag.save!(validate: false) }.to raise_error Mongo::Error::OperationFailure
    end
  end

  describe "validations" do
    it "is valid" do
      expect(tag).to be_valid
    end

    it "requires a name" do
      tag.name = nil

      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to be_include "can't be blank"
    end

    it "requires a context" do
      tag.context = nil

      expect(tag).not_to be_valid
      expect(tag.errors[:context]).to be_include "can't be blank"
    end

    it "requires a taggable_type" do
      tag.taggable_type = nil

      expect(tag).not_to be_valid
      expect(tag.errors[:taggable_type]).to be_include "can't be blank"
    end

    it "requires a unique name" do
      tag.save!

      duplicate_tag    = ActsAsTaggableOnMongoid::Models::Tag.new(tag.attributes)
      duplicate_tag.id = BSON::ObjectId.new

      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors.messages[:name]).to include("is already taken")
    end

    it "allows a duplicate name for a different context" do
      tag.save!

      duplicate_tag         = ActsAsTaggableOnMongoid::Models::Tag.new(tag.attributes)
      duplicate_tag.id      = BSON::ObjectId.new
      duplicate_tag.context = "another_context"

      expect(duplicate_tag).to be_valid

      duplicate_tag.save!
    end

    it "allows a duplicate name for a different taggable_type" do
      tag.save!

      duplicate_tag               = ActsAsTaggableOnMongoid::Models::Tag.new(tag.attributes)
      duplicate_tag.id            = BSON::ObjectId.new
      duplicate_tag.taggable_type = "String"

      expect(duplicate_tag).to be_valid

      duplicate_tag.save!
    end
  end

  describe "taggings" do
    it "deletes the taggings when a tag is deleted" do
      taggable = TaggableModel.create!(name: "Bob Smith", tag_list: "awesome, cool, hurray!")

      expect(taggable.reload.tag_list).to eq %w[awesome cool hurray!]

      expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 3
      expect(ActsAsTaggableOnMongoid::Models::Tagging.count).to eq 3

      ActsAsTaggableOnMongoid::Models::Tag.destroy_all

      expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 0
      expect(ActsAsTaggableOnMongoid::Models::Tagging.count).to eq 0

      expect(taggable.reload.tag_list).to be_blank
    end

    it "has a list of the taggings" do
      OrderedTaggableModel.create!(name: "Bob Smith", tag_list: "awesome, cool, hurray!")

      taggables = [TaggableModel.create!(name: "Bob Smith", tag_list: "awesome, cool, hurray!"),
                   TaggableModel.create!(name: "Mary Smith", tag_list: "awesome, cool, hurray!"),
                   TaggableModel.create!(name: "George Smith", tag_list: "awesome, cool, hurray!"),
                   TaggableModel.create!(name: "Sue Smith", tag_list: "awesome, cool, hurray!")]

      expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 6
      expect(ActsAsTaggableOnMongoid::Models::Tagging.count).to eq 15

      tag = ActsAsTaggableOnMongoid::Models::Tag.where(taggable_type: TaggableModel.name).to_a.sample

      expect(tag.taggings.count).to eq 4
      expect(tag.taggings.pluck(:taggable_id).sort).to eq taggables.map(&:id).sort
    end
  end

  describe "==" do
    let(:equal_tag) { ActsAsTaggableOnMongoid::Models::Tag.new(name: tag.name, context: tag.context, taggable_type: tag.taggable_type) }

    it "is equal if class name context and taggable type are equal" do
      expect(equal_tag).to eq tag
    end

    it "is not equal if classes differ" do
      equal_tag = AltTag.new(name: tag.name, context: tag.context, taggable_type: tag.taggable_type)

      expect(equal_tag).not_to eq tag
    end

    it "is not equal if taggable_type differ" do
      equal_tag.taggable_type = OrderedTaggableModel.name

      expect(equal_tag).not_to eq tag
    end

    it "is not equal if context differ" do
      equal_tag.context = "language"

      expect(equal_tag).not_to eq tag
    end
  end

  describe "to_s" do
    it "is the same as the name" do
      expect(tag.to_s).to eq tag.name
    end
  end

  describe "named_like_any" do
    it "finds records for multiple regexes" do
      tag.name = "no matches"
      tag.save!

      matchers = [ActsAsTaggableOnMongoid::Models::Tag.create!(name: "cool", context: "tags", taggable_type: TaggableModel.name),
                  ActsAsTaggableOnMongoid::Models::Tag.create!(name: "coolip", context: "language", taggable_type: OrderedTaggableModel.name),
                  ActsAsTaggableOnMongoid::Models::Tag.create!(name: "al Franken", context: "colors", taggable_type: InheritingTaggableModel.name),
                  ActsAsTaggableOnMongoid::Models::Tag.create!(name: "frankenberry", context: "freedoms", taggable_type: UntaggableModel.name)]

      expect(ActsAsTaggableOnMongoid::Models::Tag.named_like_any("cool", "fRank").pluck(:id).sort).to eq matchers.map(&:id).sort
    end
  end

  describe "for_taggable_class" do
    it "finds any record whose taggable is for that class" do
      tag.taggable_type = UntaggableModel.name
      tag.save!

      regex_matches = [ActsAsTaggableOnMongoid::Models::Tag.create!(name: "cool", context: "tags", taggable_type: TaggableModel.name),
                       ActsAsTaggableOnMongoid::Models::Tag.create!(name: "al Franken", context: "colors", taggable_type: TaggableModel.name)]

      expect(ActsAsTaggableOnMongoid::Models::Tag.for_taggable_class(TaggableModel).pluck(:id).sort).to eq regex_matches.map(&:id).sort
    end
  end

  describe "for_tag" do
    it "finds any record for a particular tag" do
      tag.context = "colors"
      tag.save!

      regex_matches = [ActsAsTaggableOnMongoid::Models::Tag.create!(name: "cool", context: "tags", taggable_type: TaggableModel.name),
                       ActsAsTaggableOnMongoid::Models::Tag.create!(name: "al Franken", context: "tags", taggable_type: TaggableModel.name)]

      expect(ActsAsTaggableOnMongoid::Models::Tag.for_tag(tag_definition).pluck(:id).sort).to eq regex_matches.map(&:id).sort
    end
  end
end
