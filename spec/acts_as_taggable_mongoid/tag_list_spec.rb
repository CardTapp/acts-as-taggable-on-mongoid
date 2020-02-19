# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::TagList do
  let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags" }
  let(:tag_list) { ActsAsTaggableOnMongoid::TagList.new(tag_definition, "awesome", "radical") }
  let(:another_tag_list) { ActsAsTaggableOnMongoid::TagList.new(tag_definition, "awesome", "crazy", "alien") }
  let(:my_user) { MyUser.create! name: "My User" }
  let(:other_user) { MyUser.create! name: "Other User" }

  it "is an Array" do
    expect(tag_list).to be_kind_of Array
  end

  describe "#add" do
    it "should be able to be add a new tag word" do
      tag_list.add("cool")
      expect(tag_list.include?("cool")).to be_truthy
    end

    it "should not parse if parse is false" do
      tag_list.add("cool, wicked", parse: false)
      expect(tag_list).to include("cool, wicked")
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

  context "no tagger allowed" do
    it "does not set tagger on assignment" do
      tag_list.add "A, tag, list", tagger: my_user

      expect(tag_list.instance_variable_defined?(:@tagger)).to be_falsey
    end

    it "does not set tagger when set explicitly" do
      tag_list.tagger = my_user

      expect(tag_list.instance_variable_defined?(:@tagger)).to be_falsey
    end
  end

  context "tagger allowed" do
    let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", tagger: true }

    it "tagger_list= allows setting tagger" do
      tag_list.add "A, tag, list", tagger: my_user

      expect(tag_list.instance_variable_defined?(:@tagger)).to be_truthy
    end

    it "The tagger can be set explicitly" do
      tag_list.tagger = my_user

      expect(tag_list.instance_variable_defined?(:@tagger)).to be_truthy
    end

    it "uses nil default tagger if non specified and no method" do
      expect(tag_list.tagger).to be_nil
    end
  end

  context "tagger default method" do
    let(:tag_definition) do
      ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", tagger: { default_tagger: :my_user }
    end
    let(:taggable) { TaggerTaggableModel.create! my_user: my_user }

    it "defaulted tagger tagger_list= allows setting tagger" do
      tag_list.taggable = taggable
      tag_list.set "A, tag, list", tagger: other_user

      expect(tag_list.tagger).to eq other_user
    end

    it "uses the default_method on the taggable if method available" do
      tag_list.taggable = taggable
      tag_list.set "A, tag, list"

      expect(tag_list.tagger).to eq my_user
    end

    describe "dup" do
      let(:dup) { tag_list.dup }

      it "creates a new list with the same taggable" do
        tag_list.set "\"A, list\", is, set", parse: true
        tag_list.taggable = taggable

        expect(dup.taggable).to eq taggable
      end

      it "creates a new list with the same tags" do
        tag_list.set "\"A, list\", is, set", parse: true
        tag_list.taggable = taggable

        expect(dup).to eq ["A, list", "is", "set"]
      end

      it "creates a new list with the same tagger if tagger is not default" do
        tag_list.set "\"A, list\", is, set", parse: true, tagger: other_user
        tag_list.taggable = taggable

        expect(dup.tagger).to eq other_user
      end

      it "creates a new list with the same tagger if tagger is not nil" do
        tag_list.set "\"A, list\", is, set", parse: true
        tag_list.taggable = taggable

        expect(dup.tagger).to eq my_user
      end

      it "creates a new list without a tagger if tagger is not set" do
        tag_list.set "\"A, list\", is, set", parse: true, tagger: nil
        tag_list.taggable = taggable

        expect(dup.tagger).to be_nil
      end
    end
  end

  describe "set" do
    it "replaces existing values" do
      tag_list.add %w[This is a list]
      tag_list.set %w[What is this to you]

      expect(tag_list).to eq %w[What is this to you]
    end

    it "parses values if set" do
      tag_list.set "This, is, a list", parse: true

      expect(tag_list).to eq ["This", "is", "a list"]
    end

    it "doesn't parse values by default" do
      tag_list.set "This, is, a list"

      expect(tag_list).to eq ["This, is, a list"]
    end

    it "uses a custom parser" do
      tag_list.set "This, is, \"a, list\"", parser: ActsAsTaggableOnMongoid::GenericParser

      expect(tag_list).to eq ["This", "is", "\"a", "list\""]
    end
  end
end
