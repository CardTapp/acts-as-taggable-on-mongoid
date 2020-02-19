# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Tagger do
  describe "acts_as_tagger" do
    context MyUser do
      let(:user) { MyUser.create! name: "My User" }
      let(:taggable) { Company.create! name: "Fake Company" }
      let(:tag) do
        ActsAsTaggableOnMongoid::Models::Tag.create! name:          "Some Tag",
                                                     context:       "tags",
                                                     taggable_type: Company.name,
                                                     owner:         user
      end
      let!(:tagging) do
        ActsAsTaggableOnMongoid::Models::Tagging.create! tag_name: "Some Tag",
                                                         context:  "tags",
                                                         tag:      tag,
                                                         tagger:   user,
                                                         taggable: taggable
      end
      let(:other_user) { MyUser.create! name: "My User" }
      let(:other_tag) do
        ActsAsTaggableOnMongoid::Models::Tag.create! name:          "Some Other Tag",
                                                     context:       "tags",
                                                     taggable_type: Company.name,
                                                     owner:         other_user
      end
      let!(:other_tagging) do
        ActsAsTaggableOnMongoid::Models::Tagging.create! tag_name: "Some Other Tag",
                                                         context:  "tags",
                                                         tag:      other_tag,
                                                         tagger:   other_user,
                                                         taggable: taggable
      end
      let(:tagger) { MyUser }

      it "should have owned_tags relation" do
        expect(tagger.respond_to?(:owned_tags))
        expect(tagger.respond_to?(:owned_taggings))
      end

      it "returns owned tags" do
        expect(user.owned_tags.count).to eq 1
        expect(user.owned_tags.first).to eq tag
      end

      it "returns owned taggings" do
        expect(user.owned_taggings.count).to eq 1
        expect(user.owned_taggings.first).to eq tagging
      end
    end

    context AltMyUser do
      let(:user) { AltMyUser.create! name: "My User" }
      let(:taggable) { Company.create! name: "Fake Company" }
      let(:tag) do
        AltTag.create! name:          "Some Tag",
                       context:       "tags",
                       taggable_type: Company.name,
                       owner:         user
      end
      let!(:tagging) do
        AltTagging.create! tag_name: "Some Tag",
                           context:  "tags",
                           tag:      tag,
                           tagger:   user,
                           taggable: taggable
      end
      let(:other_user) { MyUser.create! name: "My User" }
      let(:other_tag) do
        AltTag.create! name:          "Some Other Tag",
                       context:       "tags",
                       taggable_type: Company.name,
                       owner:         other_user
      end
      let!(:other_tagging) do
        AltTagging.create! tag_name: "Some Other Tag",
                           context:  "tags",
                           tag:      other_tag,
                           tagger:   other_user,
                           taggable: taggable
      end
      let(:tagger) { AltMyUser }

      it "should have owned_tags relation" do
        expect(tagger.respond_to?(:owned_alt_tags))
        expect(tagger.respond_to?(:owned_alt_taggings))
      end

      it "returns owned tags" do
        expect(user.owned_alt_tags.count).to eq 1
        expect(user.owned_alt_tags.first).to eq tag
      end

      it "returns owned taggings" do
        expect(user.owned_alt_taggings.count).to eq 1
        expect(user.owned_alt_taggings.first).to eq tagging
      end
    end
  end

  RSpec.shared_examples("it tags items") do
    let(:my_user) { MyUser.create name: "My User" }
    let(:tagger) { MyUser.create name: "My Tagger" }
    let(:taggable) { TaggerTaggableModel.create my_user: my_user, attribute_list => ["Other, Tags", tagger: tagger] }
    let(:on_name) { attribute_list[0..-6] }

    RSpec.shared_examples("on the specified list") do
      it "Can tags and replace tags on the taggable object" do
        tagger.send(tag_method, taggable, "This, list", on: on_name, replace: true)

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq %w[This list].sort
      end

      it "tags the taggable object" do
        tagger.send(tag_method, taggable, "This, list", on: on_name)

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq %w[Other Tags This list].sort
      end

      it "tags the taggable object using with" do
        tagger.send(tag_method, taggable, "This, list", on: on_name, with: "That, is, cool")

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq %w[Other Tags That is cool].sort
      end

      it "tags the taggable object without parsing if specified" do
        tagger.send(tag_method, taggable, "This, list", on: on_name, parse: false)

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq ["Other", "Tags", "This, list"].sort
      end

      it "tags the taggable object with specified parser" do
        tagger.send(tag_method, taggable, "\"This, list\"", on: on_name, parser: ActsAsTaggableOnMongoid::GenericParser)

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq ["Other", "Tags", "\"This", "list\""].sort
      end

      it "tags the taggable object with an array" do
        tagger.send(tag_method, taggable, "This", "list", on: on_name)

        taggable.reload
        expect(taggable.send("tagger_#{attribute_list}s")[tagger].sort).to eq %w[Other Tags This list].sort
      end

      it "calls the expected method" do
        tagger
        taggable

        allow(taggable).to receive(expected_method).and_call_original
        tagger.send(tag_method, taggable, "This", "list", on: on_name)
        expect(taggable).to have_received(expected_method).at_least(1).times
      end
    end

    context "default" do
      let(:attribute_list) { :tag_list }

      it_behaves_like "on the specified list"
    end

    %i[tag_list language_list offering_list skill_list need_list].each do |list_name|
      context list_name do
        let(:attribute_list) { list_name }

        it_behaves_like "on the specified list"
      end
    end
  end

  describe "tag" do
    let(:tag_method) { :tag }
    let(:expected_method) { :save }

    it_behaves_like "it tags items"
  end

  describe "tag!" do
    let(:tag_method) { :tag! }
    let(:expected_method) { :save! }

    it_behaves_like "it tags items"
  end
end
