# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::GenericParser do
  describe "parse" do
    it "#parse should return empty array if empty tag string is passed" do
      tag_list = ActsAsTaggableOnMongoid::GenericParser.new("")
      expect(tag_list.parse).to be_empty
    end

    it "#parse should separate tags by comma" do
      tag_list = ActsAsTaggableOnMongoid::GenericParser.new("cool,data,,I,have")
      expect(tag_list.parse).to eq(%w[cool data I have])
    end

    it "#parse should separate tags by comma ignoring quotes" do
      tag_list = ActsAsTaggableOnMongoid::GenericParser.new("cool,data,,\"I,have\"")
      expect(tag_list.parse).to eq(%w[cool data "I have"])
    end
  end

  describe "to_s" do
    it "joings all pass in items with commas" do
      expect(ActsAsTaggableOnMongoid::GenericParser.new("cool", "data", "I", "have").to_s).to eq "cool,data,I,have"
    end

    it "join all passed in items with commas (no quotes)" do
      expect(ActsAsTaggableOnMongoid::GenericParser.new("cool", "data", "I,have").to_s).to eq "cool,data,I,have"
    end

    it "ignores empty arguments" do
      expect(ActsAsTaggableOnMongoid::GenericParser.new.to_s).to eq ""
    end
  end
end
