# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Tagging do
  let!(:tagging) { ActsAsTaggableOnMongoid::Models::Tagging.new }

  context "ActsAsTaggableOn" do
    it "should not be valid with a invalid tag" do
      tagging.taggable = TaggableModel.create(name: "Bob Jones")
      tagging.tag_name = "tag"
      tagging.tag_id   = BSON::ObjectId.new
      tagging.context  = "tags"

      expect(tagging).to_not be_valid

      expect(tagging.errors[:tag]).to eq(["can't be blank"])
    end

    it "should not create duplicate taggings" do
      taggable = TaggableModel.create(name: "Bob Jones")
      tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name:          "awesome",
                                                             context:       "tags",
                                                             taggable_type: TaggableModel.name)

      expect do
        2.times { ActsAsTaggableOnMongoid::Models::Tagging.create(taggable: taggable, tag: tag, context: "tags", tag_name: "awesome") }
      end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
    end

    it "should re-raise error if it is not because of duplicate names" do
      taggable = TaggableModel.create(name: "Bob Jones")
      tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name:          "awesome",
                                                             context:       "tags",
                                                             taggable_type: TaggableModel.name)

      allow(ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff).to receive(:new).and_wrap_original do |orig_method, *args|
        diff = orig_method.call(**args[0])

        allow(diff).to receive(:ignore_tagging_error).and_return false

        diff
      end

      expect do
        2.times do
          ActsAsTaggableOnMongoid::Models::Tagging.create(taggable: taggable, tag: tag, context: "tags", tag_name: "awesome")
          taggable.save!
        end
      end.to raise_error Mongoid::Errors::Validations
    end

    it "should not delete tags of other records" do
      6.times { TaggableModel.create(name: "Bob Jones", tag_list: "very, serious, bug") }
      expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq(3)
      taggable          = TaggableModel.first
      taggable.tag_list = "bug"
      taggable.save

      expect(taggable.tag_list).to eq(["bug"])

      another_taggable = TaggableModel.where(:id.ne => taggable.id).sample
      expect(another_taggable.tag_list.sort).to eq(%w[very serious bug].sort)
    end

    context "remove_unused_tags" do
      around(:each) do |example_proxy|
        previous_setting          = ActsAsTaggableOnMongoid.remove_unused_tags?
        taggable_previous_setting = TaggableModel.tag_types[:tags].remove_unused_tags?

        begin
          example_proxy.run
        ensure
          ActsAsTaggableOnMongoid.remove_unused_tags = previous_setting
          TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, taggable_previous_setting
        end
      end

      it "should destroy unused tags after tagging destroyed" do
        TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, true
        ActsAsTaggableOnMongoid::Models::Tag.destroy_all

        taggable = TaggableModel.create(name: "Bob Jones")

        taggable.update_attribute :tag_list, "aaa,bbb,ccc"
        taggable.update_attribute :tag_list, ""

        expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eql(0)
      end
    end

    describe "context scopes" do
      let(:tagging_2) { ActsAsTaggableOnMongoid::Models::Tagging.new }
      let(:tagging_3) { ActsAsTaggableOnMongoid::Models::Tagging.new }
      let(:tagger) { MyUser.new }
      let(:tagger_2) { MyUser.new }

      before(:each) do
        tagging.taggable = TaggableModel.create(name: "Black holes")
        tagging.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name:          "Physics",
                                                                       context:       "Science",
                                                                       taggable_type: TaggableModel.name)
        tagging.tagger   = tagger
        tagging.context  = "Science"
        tagging.tag_name = "Physics"
        tagging.save!

        tagging_2.taggable = TaggableModel.create(name: "Satellites")
        tagging_2.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name:          "Technology",
                                                                         context:       "Science",
                                                                         taggable_type: TaggableModel.name)
        tagging_2.tagger   = tagger_2
        tagging_2.context  = "Science"
        tagging_2.tag_name = "Technology"
        tagging_2.save!

        tagging_3.taggable = TaggableModel.create(name: "Satellites")
        tagging_3.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name:          "Engineering",
                                                                         context:       "Astronomy",
                                                                         taggable_type: TaggableModel.name)
        tagging_3.tagger   = tagger_2
        tagging_3.context  = "Astronomy"
        tagging_3.tag_name = "Engineering"
        tagging_3.save!
      end

      # TODO: Not implemented yet
      describe ".owned_by" do
        it "should belong to a specific user" do
          expect(ActsAsTaggableOnMongoid::Models::Tagging.owned_by(tagger).first).to eq(tagging)
        end
      end

      describe ".by_tag_type" do
        it "should be found by context" do
          expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_type("Science").length).to eq(2)
        end
      end

      describe ".by_tag_types" do
        it "should find taggings by contexts" do
          expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_types("Science", "Astronomy").first).to eq(tagging)
          expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_types("Science", "Astronomy").second).to eq(tagging_2)
          expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_types("Science", "Astronomy").third).to eq(tagging_3)
          expect(ActsAsTaggableOnMongoid::Models::Tagging.by_tag_types("Science", "Astronomy").length).to eq(3)
        end
      end

      describe ".not_owned" do
        let(:tagging_4) { ActsAsTaggableOnMongoid::Models::Tagging.new }

        before(:each) do
          tagging_4.taggable = TaggableModel.create(name: "Gravity")
          tagging_4.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name: "Space")
          tagging_4.context  = "Science"
          tagging_4.tag_name = "Space"
          tagging_4.save
        end

        # TODO: Not implemented yet
        xit "should found the taggings that do not have owner" do
          expect(ActsAsTaggableOnMongoid::Models::Tagging.all.length).to eq(4)
          expect(ActsAsTaggableOnMongoid::Models::Tagging.not_owned.length).to eq(1)
          expect(ActsAsTaggableOnMongoid::Models::Tagging.not_owned.first).to eq(tagging_4)
        end
      end
    end
  end

  context "taggings" do
    let!(:taggable) { TaggableModel.create! name: "Tag Me", tag_list: "awesome" }
    let!(:tag) { ActsAsTaggableOnMongoid::Models::Tag.where(name: "awesome", context: "tags", taggable_type: TaggableModel.name).first }
    let!(:tagging) { ActsAsTaggableOnMongoid::Models::Tagging.where(tag_name: "awesome", context: "tags", taggable: taggable, tag: tag).first }

    describe "unique indexes" do
      it "does not allow the creation of duplicate taggings" do
        duplicate_tagging    = ActsAsTaggableOnMongoid::Models::Tagging.new(tagging.attributes)
        duplicate_tagging.id = BSON::ObjectId.new

        expect(duplicate_tagging).not_to be_valid
        expect(duplicate_tagging.errors[:tag_name]).to eq(["has already been taken"])
        expect(duplicate_tagging.errors[:tag_id]).to eq(["has already been taken"])

        expect { duplicate_tagging.save!(validate: false) }.to raise_error Mongo::Error::OperationFailure
      end
    end

    describe "validations" do
      it "is valid" do
        expect(tagging).to be_valid
      end

      it "requires tag_name" do
        tagging.tag_name = nil

        expect(tagging).not_to be_valid
        expect(tagging.errors[:tag_name]).to eq(["can't be blank"])
      end

      it "requires context" do
        tagging.context = nil

        expect(tagging).not_to be_valid
        expect(tagging.errors[:context]).to eq(["can't be blank"])
      end

      it "requires tag" do
        tagging.tag_id = BSON::ObjectId.new

        expect(tagging).not_to be_valid
        expect(tagging.errors[:tag]).to eq(["can't be blank"])
      end

      it "requires taggable" do
        tagging.taggable_id = BSON::ObjectId.new

        expect(tagging).not_to be_valid
        expect(tagging.errors[:taggable]).to eq(["can't be blank"])
      end

      it "does not allow duplicate tag_name" do
        new_tag                  = ActsAsTaggableOnMongoid::Models::Tag.create! name: "new_tag", context: "tags", taggable_type: TaggableModel.name
        duplicate_tagging        = ActsAsTaggableOnMongoid::Models::Tagging.new(tagging.attributes)
        duplicate_tagging.id     = BSON::ObjectId.new
        duplicate_tagging.tag_id = new_tag.id

        expect(duplicate_tagging).not_to be_valid
        expect(duplicate_tagging.errors[:tag_name]).to eq(["has already been taken"])
      end

      it "does not allow duplicate tag_id" do
        duplicate_tagging          = ActsAsTaggableOnMongoid::Models::Tagging.new(tagging.attributes)
        duplicate_tagging.id       = BSON::ObjectId.new
        duplicate_tagging.tag_name = "new_tag"

        expect(duplicate_tagging).not_to be_valid
        expect(duplicate_tagging.errors[:tag_id]).to eq(["has already been taken"])
      end

      it "does allow duplicate tag_name for different context" do
        duplicate_tagging         = ActsAsTaggableOnMongoid::Models::Tagging.new(tagging.attributes)
        duplicate_tagging.id      = BSON::ObjectId.new
        duplicate_tagging.context = "languages"

        expect(duplicate_tagging).to be_valid
      end

      it "does allow duplicate tag_name for different taggable" do
        duplicate_tagging          = ActsAsTaggableOnMongoid::Models::Tagging.new(tagging.attributes)
        duplicate_tagging.id       = BSON::ObjectId.new
        duplicate_tagging.taggable = TaggableModel.create! name: "Newest Taggable"

        expect(duplicate_tagging).to be_valid
      end
    end

    describe "destroy" do
      around(:each) do |example_proxy|
        previous_setting          = ActsAsTaggableOnMongoid.remove_unused_tags?
        taggable_previous_setting = TaggableModel.tag_types[:tags].remove_unused_tags?

        begin
          example_proxy.run
        ensure
          ActsAsTaggableOnMongoid.remove_unused_tags = previous_setting
          TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, taggable_previous_setting
        end
      end

      context "do not remove unused tags" do
        it "does not destroy the tag if it is the last tagging" do
          tagging.destroy!

          expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 1
        end
      end

      context "remove unused tags" do
        before(:each) do
          TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, true
        end

        it "does destroy the tag if it is the last tagging" do
          tagging.destroy!

          expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 0
        end

        it "does not destroy the tag if it is not the last tagging" do
          TaggableModel.create!(name: "Another Tagging", tag_list: tagging.tag_name)

          tagging.destroy!

          expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq 1
        end
      end
    end

    describe "for_tag" do
      it "only finds the taggings for the indicated tag" do
        TaggableModel.create!(name: "Another Tagging", tag_list: "tag 1, tag 2, tag 3", language_list: "lang 1, lang 2, lang 3")
        TaggableModel.create!(name: "Second Tagging", tag_list: "tag 1, tag 4, tag 5", language_list: "lang 1, lang 2, lang 3")
        OrderedTaggableModel.create!(name: "Another Tagging", tag_list: "tag 6, tag 7, tag 8")

        expect(ActsAsTaggableOnMongoid::Models::Tagging.for_tag(TaggableModel.tag_types[:tags]).pluck(:tag_name).sort).
            to eq ["awesome", "tag 1", "tag 1", "tag 2", "tag 3", "tag 4", "tag 5"]
      end
    end

    describe "taggings_count" do
      RSpec.shared_examples("Tagging keeps Tag count") do
        let(:taggables) do
          Array.new(3) { taggable_model.create!(name: "Another Tagging", tag_field => "tag 1, tag 2, tag 3") }
        end
        let(:tagging) { tag.taggings.to_a.sample }
        let(:tag) { taggables.sample.send(tags_field).to_a.sample }

        it "updates the tags taggings_count" do
          expect(tag.taggings_count).to eq 3
        end

        it "updates the tags taggings_count on delete" do
          expect(tag.taggings_count).to eq 3

          tagging.destroy

          expect(tag.reload.taggings_count).to eq 2
        end
      end

      context "Tagging" do
        let(:taggable_model) { TaggableModel }
        let(:tag_field) { :tag_list }
        let(:tags_field) { :tags }

        it_behaves_like "Tagging keeps Tag count"
      end

      context "AltTagging" do
        let(:taggable_model) { AltTagged }
        let(:tag_field) { :tag_list }
        let(:tags_field) { :tags }

        it_behaves_like "Tagging keeps Tag count"
      end

      context "AltTagging - OtherAltTag" do
        let(:taggable_model) { AltTagged }
        let(:tag_field) { :alt_tagging_other_tag_list }
        let(:tags_field) { :alt_tagging_other_tags }

        it_behaves_like "Tagging keeps Tag count"
      end

      context "OtherTagging" do
        let(:taggable_model) { AltTagged }
        let(:tag_field) { :other_tagging_alt_tag_list }
        let(:tags_field) { :other_tagging_alt_tags }

        it_behaves_like "Tagging keeps Tag count"
      end

      context "OtherTagging - OtherOtherTag" do
        let(:taggable_model) { AltTagged }
        let(:tag_field) { :another_other_tagging_other_tag_list }
        let(:tags_field) { :another_other_tagging_other_tags }

        it_behaves_like "Tagging keeps Tag count"
      end
    end
  end
end
