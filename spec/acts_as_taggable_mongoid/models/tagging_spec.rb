# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Tagging do
  let!(:tagging) { ActsAsTaggableOnMongoid::Models::Tagging.new }

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
    tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name: "awesome")

    expect(-> {
      2.times { ActsAsTaggableOnMongoid::Models::Tagging.create(taggable: taggable, tag: tag, context: "tags", tag_name: "awesome") }
    }).to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
  end

  it "should not delete tags of other records" do
    6.times { TaggableModel.create(name: "Bob Jones", tag_list: "very, serious, bug") }
    expect(ActsAsTaggableOnMongoid::Models::Tag.count).to eq(3)
    taggable          = TaggableModel.first
    taggable.tag_list = "bug"
    taggable.save

    expect(taggable.tag_list).to eq(["bug"])

    another_taggable = TaggableModel.where(:id.ne => taggable.id).sample
    expect(another_taggable.tag_list.sort).to eq(%w(very serious bug).sort)
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

    before(:each) do
      # TODO: Not currently supported.
      # tagger   = User.new
      # tagger_2 = User.new

      tagging.taggable = TaggableModel.create(name: "Black holes")
      tagging.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name: "Physics")
      # tagging.tagger   = tagger
      tagging.context  = "Science"
      tagging.tag_name = "Physics"
      tagging.save!

      tagging_2.taggable = TaggableModel.create(name: "Satellites")
      tagging_2.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name: "Technology")
      # tagging_2.tagger   = tagger_2
      tagging_2.context  = "Science"
      tagging_2.tag_name = "Technology"
      tagging_2.save!

      tagging_3.taggable = TaggableModel.create(name: "Satellites")
      tagging_3.tag      = ActsAsTaggableOnMongoid::Models::Tag.create(name: "Engineering")
      # tagging_3.tagger   = tagger_2
      tagging_3.context  = "Astronomy"
      tagging_3.tag_name = "Engineering"
      tagging_3.save!
    end

    # TODO: Not implemented yet
    describe ".owned_by" do
      xit "should belong to a specific user" do
        expect(ActsAsTaggableOnMongoid::Models::Tagging.owned_by(tagger).first).to eq(tagging)
      end
    end

    describe ".by_context" do
      it "should be found by context" do
        expect(ActsAsTaggableOnMongoid::Models::Tagging.by_context("Science").length).to eq(2);
      end
    end

    describe ".by_contexts" do
      it "should find taggings by contexts" do
        expect(ActsAsTaggableOnMongoid::Models::Tagging.by_contexts("Science", "Astronomy").first).to eq(tagging)
        expect(ActsAsTaggableOnMongoid::Models::Tagging.by_contexts("Science", "Astronomy").second).to eq(tagging_2)
        expect(ActsAsTaggableOnMongoid::Models::Tagging.by_contexts("Science", "Astronomy").third).to eq(tagging_3)
        expect(ActsAsTaggableOnMongoid::Models::Tagging.by_contexts("Science", "Astronomy").length).to eq(3)
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
