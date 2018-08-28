# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::Changeable do
  let(:taggable) { TaggableModel.create! name: "Teth Adam", language_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }
  let(:tag_description) { TaggableModel.tag_types[:languages] }

  describe "tag_list_on_changed" do
    it "calls attribute_will_change" do
      expect(taggable).to receive(:attribute_will_change!).with "language_list"

      taggable.tag_list_on_changed(tag_description)
    end
  end

  describe "reload" do
    it "resets the language_list and all_language_list instance variables" do
      taggable.language_list
      taggable.all_languages_list

      expect(taggable.instance_variable_get(:@language_list)).to be_present
      expect(taggable.instance_variable_get(:@all_languages_list)).to be_present

      taggable.reload

      expect(taggable.instance_variable_get(:@language_list)).to be_nil
      expect(taggable.instance_variable_get(:@all_languages_list)).to be_nil
    end
  end

  describe "changed" do
    around(:each) do |example_proxy|
      tag_definition = TaggableModel.tag_types[:needs]
      orig_default   = tag_definition&.instance_variable_get(:@default)

      begin
        tag_definition&.send(:default_value=, ["defaulted, tag, \"lists, are\", fun", parser: ActsAsTaggableOnMongoid::GenericParser])

        example_proxy.run
      ensure
        tag_definition&.instance_variable_set(:@default, orig_default)
      end
    end

    it "returns all changed fields" do
      taggable.language_list = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
      taggable.tag_list      = "tag, list"
      taggable.need_list     = nil
      taggable.offering_list = "fred"
      taggable.offering_list = nil
      taggable.name          = "Billy Batson"

      expect(taggable.changed.sort).to eq %w[language_list tag_list name need_list].sort
    end
  end

  describe "changes" do
    it "returns all changed fields" do
      taggable.language_list = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
      taggable.tag_list      = "tag, list"
      taggable.name          = "Billy Batson"

      expect(taggable.changes).to eq "language_list" => [%w[Solomon Hercules Atlas Zeus Achilles Mercury],
                                                         %w[Shu Heru Amon Zehuti Aton Mehen]],
                                     "name"          => ["Teth Adam", "Billy Batson"],
                                     "tag_list"      => [[], %w[tag list]]
    end
  end

  describe "setters" do
    it "does not return tag fields" do
      taggable.language_list = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
      taggable.tag_list      = "tag, list"
      taggable.name          = "Billy Batson"

      expect(taggable.setters).to eq "name" => "Billy Batson"
    end
  end
end
