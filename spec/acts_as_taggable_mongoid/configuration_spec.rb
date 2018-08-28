# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Configuration do
  around(:each) do |example_proxy|
    orig_force_lowercase    = ActsAsTaggableOnMongoid.force_lowercase
    orig_force_parameterize = ActsAsTaggableOnMongoid.force_parameterize
    orig_remove_unused_tags = ActsAsTaggableOnMongoid.remove_unused_tags
    orig_default_parser     = ActsAsTaggableOnMongoid.default_parser
    orig_tags_table         = ActsAsTaggableOnMongoid.tags_table
    orig_taggings_table     = ActsAsTaggableOnMongoid.taggings_table
    orig_preserve_tag_order = ActsAsTaggableOnMongoid.preserve_tag_order

    begin
      example_proxy.run
    ensure
      ActsAsTaggableOnMongoid.configure do |config|
        config.force_lowercase    = orig_force_lowercase
        config.force_parameterize = orig_force_parameterize
        config.remove_unused_tags = orig_remove_unused_tags
        config.default_parser     = orig_default_parser
        config.tags_table         = orig_tags_table
        config.taggings_table     = orig_taggings_table
        config.preserve_tag_order = orig_preserve_tag_order
      end
    end
  end

  describe "configure" do
    it "yeilds the taggable configuration" do
      ActsAsTaggableOnMongoid.configure do |config|
        expect(config).to eq ActsAsTaggableOnMongoid.configuration
      end
    end
  end

  describe "force_lowercase" do
    it "defaults the value to false" do
      expect(ActsAsTaggableOnMongoid.force_lowercase).to eq false
      expect(ActsAsTaggableOnMongoid.force_lowercase?).to eq false
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.force_lowercase = "a new fake value"
      expect(ActsAsTaggableOnMongoid.force_lowercase).to eq "a new fake value"
      expect(ActsAsTaggableOnMongoid.force_lowercase?).to eq "a new fake value"
    end
  end

  describe "force_parameterize" do
    it "defaults the value to false" do
      expect(ActsAsTaggableOnMongoid.force_parameterize).to eq false
      expect(ActsAsTaggableOnMongoid.force_parameterize?).to eq false
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.force_parameterize = "a new fake value"
      expect(ActsAsTaggableOnMongoid.force_parameterize).to eq "a new fake value"
      expect(ActsAsTaggableOnMongoid.force_parameterize?).to eq "a new fake value"
    end
  end

  describe "preserve_tag_order" do
    it "defaults the value to false" do
      expect(ActsAsTaggableOnMongoid.preserve_tag_order).to eq false
      expect(ActsAsTaggableOnMongoid.preserve_tag_order?).to eq false
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.preserve_tag_order = "a new fake value"
      expect(ActsAsTaggableOnMongoid.preserve_tag_order).to eq "a new fake value"
      expect(ActsAsTaggableOnMongoid.preserve_tag_order?).to eq "a new fake value"
    end
  end

  describe "remove_unused_tags" do
    it "defaults the value to false" do
      expect(ActsAsTaggableOnMongoid.remove_unused_tags).to eq false
      expect(ActsAsTaggableOnMongoid.remove_unused_tags?).to eq false
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.remove_unused_tags = "a new fake value"
      expect(ActsAsTaggableOnMongoid.remove_unused_tags).to eq "a new fake value"
      expect(ActsAsTaggableOnMongoid.remove_unused_tags?).to eq "a new fake value"
    end
  end

  describe "default_parser" do
    it "defaults the value to DefaultParser" do
      expect(ActsAsTaggableOnMongoid.default_parser).to eq ActsAsTaggableOnMongoid::DefaultParser
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.default_parser = "a new fake value"
      expect(ActsAsTaggableOnMongoid.default_parser).to eq "a new fake value"
    end
  end

  describe "tags_table" do
    it "defaults the value to ActsAsTaggableOnMongoid::Models::Tag" do
      expect(ActsAsTaggableOnMongoid.tags_table).to eq ActsAsTaggableOnMongoid::Models::Tag
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.tags_table = "a new fake value"
      expect(ActsAsTaggableOnMongoid.tags_table).to eq "a new fake value"
    end
  end

  describe "taggings_table" do
    it "defaults the value to ActsAsTaggableOnMongoid::Models::Tagging" do
      expect(ActsAsTaggableOnMongoid.taggings_table).to eq ActsAsTaggableOnMongoid::Models::Tagging
    end

    it "allows the user to set a value" do
      ActsAsTaggableOnMongoid.taggings_table = "a new fake value"
      expect(ActsAsTaggableOnMongoid.taggings_table).to eq "a new fake value"
    end
  end

  describe "tags_counter" do
    it "returns nil" do
      expect(ActsAsTaggableOnMongoid.tags_counter).to be_nil
      expect(ActsAsTaggableOnMongoid.tags_counter?).to be_nil
    end

    it "does not set" do
      ActsAsTaggableOnMongoid.tags_counter = "a new fake value"

      expect(ActsAsTaggableOnMongoid.tags_counter).to be_nil
      expect(ActsAsTaggableOnMongoid.tags_counter?).to be_nil
    end
  end

  describe "strict_case_match" do
    it "returns nil" do
      expect(ActsAsTaggableOnMongoid.strict_case_match).to be_nil
      expect(ActsAsTaggableOnMongoid.strict_case_match?).to be_nil
    end

    it "does not set" do
      ActsAsTaggableOnMongoid.strict_case_match = "a new fake value"

      expect(ActsAsTaggableOnMongoid.strict_case_match).to be_nil
      expect(ActsAsTaggableOnMongoid.strict_case_match?).to be_nil
    end
  end
end
