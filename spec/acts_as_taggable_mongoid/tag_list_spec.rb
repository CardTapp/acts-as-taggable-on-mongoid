# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::TagList do
  let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags" }
  let(:tag_list) { ActsAsTaggableOnMongoid::TagList.new(tag_definition, "awesome", "radical") }
  let(:another_tag_list) { ActsAsTaggableOnMongoid::TagList.new(tag_definition, "awesome", "crazy", "alien") }

  it "is an Array" do
    expect(tag_list).to be_kind_of Array
  end

  describe "#add" do
    it "should be able to be add a new tag word" do
      tag_list.add("cool")
      expect(tag_list.include?("cool")).to be_truthy
    end

    it "should be able to add delimited lists of words" do
      tag_list.add("cool, wicked", parse: true)
      expect(tag_list).to include("cool", "wicked")
    end

    it "should be able to add delimited list of words with quoted delimiters" do
      tag_list.add("'cool, wicked', \"really cool, really wicked\"", parse: true)
      expect(tag_list).to include("cool, wicked", "really cool, really wicked")
    end

    it "should be able to handle other uses of quotation marks correctly" do
      tag_list.add("john's cool car, mary's wicked toy", parse: true)
      expect(tag_list).to include("john's cool car", "mary's wicked toy")
    end

    it "should be able to add an array of words" do
      tag_list.add(%w[cool wicked], parse: true)
      expect(tag_list).to include("cool", "wicked")
    end

    it "should quote escape tags with commas in them" do
      tag_list.add("cool", "rad,bodacious")
      expect(tag_list.to_s).to eq("awesome,radical,cool,\"rad,bodacious\"")
    end
  end

  describe "#remove" do
    it "should be able to remove words" do
      tag_list.remove("awesome")
      expect(tag_list).to_not include("awesome")
    end

    it "should be able to remove delimited lists of words" do
      tag_list.remove("awesome, radical", parse: true)
      expect(tag_list).to be_empty
    end

    it "should be able to remove an array of words" do
      tag_list.remove(%w[awesome radical], parse: true)
      expect(tag_list).to be_empty
    end
  end

  describe "#+" do
    it "should not have duplicate tags" do
      new_tag_list = tag_list + another_tag_list
      expect(tag_list).to eq(%w[awesome radical])
      expect(another_tag_list).to eq(%w[awesome crazy alien])
      expect(new_tag_list).to eq(%w[awesome radical crazy alien])
    end

    it "should have class: ActsAsTaggableOnMongoid::TagList" do
      new_tag_list = tag_list + another_tag_list
      expect(new_tag_list.class).to eq(ActsAsTaggableOnMongoid::TagList)
    end
  end

  describe "#concat" do
    it "should not have duplicate tags" do
      expect(tag_list.concat(another_tag_list)).to eq(%w[awesome radical crazy alien])
    end

    it "should have class: ActsAsTaggableOnMongoid::TagList" do
      new_tag_list = tag_list.concat(another_tag_list)
      expect(new_tag_list.class).to eq(ActsAsTaggableOnMongoid::TagList)
    end

    context "without duplicates" do
      let(:arr) { %w[crazy alien] }
      let(:another_tag_list) { ActsAsTaggableOnMongoid::TagList.new(tag_definition, *arr) }
      it "adds other list" do
        expect(tag_list.concat(another_tag_list)).to eq(%w[awesome radical crazy alien])
      end

      it "adds other array" do
        expect(tag_list.concat(arr)).to eq(%w[awesome radical crazy alien])
      end
    end
  end

  describe "#to_s" do
    it "should give a delimited list of words when converted to string" do
      expect(tag_list.to_s).to eq("awesome,radical")
    end

    it "should be able to call to_s on a frozen tag list" do
      tag_list.freeze
      expect { tag_list.add("cool", "rad,bodacious") }.to raise_error(RuntimeError)
      expect { tag_list.to_s }.to_not raise_error
    end
  end

  describe "cleaning" do
    it "should parameterize if force_parameterize is set to true" do
      ActsAsTaggableOnMongoid.force_parameterize = true
      tag_list                                   = ActsAsTaggableOnMongoid::TagList.new(tag_definition, "awesome()", "radical)(cc")

      expect(tag_list).to eq(%w[awesome radical-cc])
      ActsAsTaggableOnMongoid.force_parameterize = false
    end

    it "should lowercase if force_lowercase is set to true" do
      ActsAsTaggableOnMongoid.force_lowercase = true

      tag_list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, "aweSomE", "RaDicaL", "Entrée")
      expect(tag_list).to eq(%w[awesome radical entrée])

      ActsAsTaggableOnMongoid.force_lowercase = false
    end

    it "should ignore case when removing duplicates if strict_case_match is false" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", force_lowercase: true
      tag_list       = ActsAsTaggableOnMongoid::TagList.new(tag_definition, "Junglist", "JUNGLIST", "Junglist", "Massive", "MASSIVE", "MASSIVE")

      expect(tag_list.to_s).to eq("junglist,massive")
    end

    it "should not ignore case when removing duplicates if strict_case_match is true" do
      tag_list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, "Junglist", "JUNGLIST", "Junglist", "Massive", "MASSIVE", "MASSIVE")

      expect(tag_list.to_s).to eq("Junglist,JUNGLIST,Massive,MASSIVE")
    end
  end

  describe "custom parser" do
    let(:parser) { double(parse: %w[cool wicked]) }
    let(:parser_class) { stub_const("MyParser", Class) }

    it "should use a the default parser if none is set as parameter" do
      allow(ActsAsTaggableOnMongoid.default_parser).to receive(:new).and_return(parser)
      ActsAsTaggableOnMongoid::TagList.new(tag_definition, "cool, wicked", parse: true)

      expect(parser).to have_received(:parse)
    end

    it "should use the custom parser passed as parameter" do
      allow(parser_class).to receive(:new).and_return(parser)

      ActsAsTaggableOnMongoid::TagList.new(tag_definition, "cool, wicked", parser: parser_class)

      expect(parser).to have_received(:parse)
    end

    it "should use the parser setted as attribute" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", parser: parser_class

      allow(parser_class).to receive(:new).with("new, tag").and_return(parser)

      tag_list = ActsAsTaggableOnMongoid::TagList.new(tag_definition, "example")
      tag_list.add("new, tag", parse: true)

      expect(parser).to have_received(:parse)
    end
  end
end
