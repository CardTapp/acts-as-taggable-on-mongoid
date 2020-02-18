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

  describe "mass assignment" do
    let(:my_user) { MyUser.create! name: "My User" }
    let(:initial_user) { MyUser.create! name: "Initial User" }
    let(:other_user) { MyUser.create! name: "Other User" }

    RSpec.shared_examples("with the passed in tag list") do
      it "uses the default tagger if not specified" do
        tagger_obj.send(mass_method, my_user: my_user, attribute_list => %w[A list])

        default_list = test_taggable.public_send(attribute_list)
        expect(default_list).to eq %w[A list]
        expect(default_list.tagger).to eq default_tagger
      end

      it "uses a specified tagger" do
        tagger_obj.send(mass_method, my_user: my_user, attribute_list => ["A", "list", tagger: other_user])

        tagger_lists = test_taggable.public_send("tagger_#{attribute_list}s")
        expect(tagger_lists[other_user]).to eq %w[A list]
      end

      it "uses a tagger specified in the parameters after (if applicable)" do
        tagger_obj.send(mass_method, attribute_list => %w[A list], my_user: my_user)

        default_list = test_taggable.public_send(attribute_list)
        expect(default_list).to eq %w[A list]
        expect(default_list.tagger).to eq default_tagger
      end

      it "parses by default" do
        tagger_obj.send(mass_method, my_user: my_user, attribute_list => "A, list")

        default_list = test_taggable.public_send(attribute_list)
        expect(default_list).to eq %w[A list]
        expect(default_list.tagger).to eq default_tagger
      end

      it "does not parse if told not to" do
        tagger_obj.send(mass_method, my_user: my_user, attribute_list => ["A, list", parse: false])

        default_list = test_taggable.public_send(attribute_list)
        expect(default_list).to eq ["A, list"]
        expect(default_list.tagger).to eq default_tagger
      end

      it "ueses a custom parser" do
        tagger_obj.send(mass_method, my_user: my_user, attribute_list => ["\"A, list\"", parser: ActsAsTaggableOnMongoid::GenericParser])

        default_list = test_taggable.public_send(attribute_list)
        expect(default_list).to eq ["\"A", "list\""]
        expect(default_list.tagger).to eq default_tagger
      end
    end

    RSpec.shared_examples("allows mass assignment") do
      context("tag_list") do
        let(:attribute_list) { :tag_list }
        let(:default_tagger) { nil }

        it_behaves_like "with the passed in tag list"
      end

      context("language_list") do
        let(:attribute_list) { :language_list }
        let(:default_tagger) { MyUser.find_or_create_by! name: "Language User" }

        it_behaves_like "with the passed in tag list"
      end

      context("skill_list") do
        let(:attribute_list) { :skill_list }
        let(:default_tagger) { nil }

        it_behaves_like "with the passed in tag list"
      end

      context("need_list") do
        let(:attribute_list) { :need_list }
        let(:default_tagger) { my_user }

        it_behaves_like "with the passed in tag list"
      end

      context("offering_list") do
        let(:attribute_list) { :offering_list }
        let(:default_tagger) { my_user }

        it_behaves_like "with the passed in tag list"
      end
    end

    context "create" do
      let(:tagger_obj) { TaggerTaggableModel }
      let(:mass_method) { :create! }
      let(:test_taggable) { TaggerTaggableModel.first }

      it_behaves_like "allows mass assignment"
    end

    context "update_attributes" do
      let(:tagger_obj) { TaggerTaggableModel.create! my_user: initial_user }
      let(:mass_method) { :update_attributes }
      let(:test_taggable) { tagger_obj }

      it_behaves_like "allows mass assignment"
    end

    context "assign_attributes" do
      let(:tagger_obj) { TaggerTaggableModel.create! my_user: initial_user }
      let(:mass_method) { :assign_attributes }
      let(:test_taggable) { tagger_obj }

      it_behaves_like "allows mass assignment"
    end
  end
end
