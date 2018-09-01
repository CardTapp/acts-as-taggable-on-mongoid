# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::DefaultParser do
  around(:each) do |example_proxy|
    orig_delimiter = ActsAsTaggableOnMongoid::DefaultParser.delimiter

    begin
      example_proxy.call
    ensure
      ActsAsTaggableOnMongoid::DefaultParser.delimiter = orig_delimiter
    end
  end

  describe "parse" do
    it "#parse should return empty array if empty array is passed" do
      parser = ActsAsTaggableOnMongoid::DefaultParser.new([])

      expect(parser.parse).to be_empty
    end

    describe "Multiple Delimiter" do
      before do
        @old_delimiter = ActsAsTaggableOnMongoid::DefaultParser.delimiter
      end

      after do
        ActsAsTaggableOnMongoid::DefaultParser.delimiter = @old_delimiter
      end

      it "should separate tags by delimiters" do
        ActsAsTaggableOnMongoid::DefaultParser.delimiter = [",", " ", "\\|"]
        parser                                           = ActsAsTaggableOnMongoid::DefaultParser.new("cool, data|I have")
        expect(parser.parse.sort).to eq(["", "I", "cool", "data", "have"])
      end

      it "should escape quote" do
        ActsAsTaggableOnMongoid::DefaultParser.delimiter = [",", " ", "\\|"]

        parser = ActsAsTaggableOnMongoid::DefaultParser.new("'I have'|cool, data")

        expect(parser.parse.sort).to eq(["", "", "I have", "cool", "data"])

        parser = ActsAsTaggableOnMongoid::DefaultParser.new("\"I, have\"|cool, data")

        expect(parser.parse.sort).to eq(["", "", "I, have", "cool", "data"])
      end

      it "should work for utf8 delimiter and long delimiter" do
        ActsAsTaggableOnMongoid::DefaultParser.delimiter = ["，", "的", "可能是"]

        parser = ActsAsTaggableOnMongoid::DefaultParser.new("我的东西可能是不见了，还好有备份")

        expect(parser.parse.sort).to eq(%w[我 东西 不见了 还好有备份].sort)
      end

      it "should work for multiple quoted tags" do
        ActsAsTaggableOnMongoid::DefaultParser.delimiter = [","]
        parser                                           = ActsAsTaggableOnMongoid::DefaultParser.new("\"Ruby Monsters\",\"eat Katzenzungen\"")
        expect(parser.parse.sort).to eq(["Ruby Monsters", "eat Katzenzungen"])
      end
    end
  end

  describe "stringify_tag_list" do
    before(:each) do
      ActsAsTaggableOnMongoid::DefaultParser.delimiter = [",", " ", "\\|"]
    end

    it "joings all pass in items with first delimeter" do
      ActsAsTaggableOnMongoid::DefaultParser.delimiter = ["，", "的", "可能是"]

      expect(ActsAsTaggableOnMongoid::DefaultParser.stringify_tag_list("cool", "data", "I", "have")).to eq "cool，data，I，have"
    end

    it "join all passed in items with commas and adds quotes" do
      expect(ActsAsTaggableOnMongoid::DefaultParser.stringify_tag_list("cool", "data", "I,have")).to eq "cool,data,\"I,have\""
    end

    it "ignores empty arguments" do
      expect(ActsAsTaggableOnMongoid::DefaultParser.stringify_tag_list).to eq ""
    end
  end
end
