# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Attributes do
  describe "cached_in_model" do
    RSpec.shared_examples "saves cached_in_model" do
      let(:alt_tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", cached_in_model: true }

      it "defaults to false" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to be_falsey
      end

      it "returns false if set false" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", cached_in_model: false

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq false
      end

      it "returns true if set true" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", cached_in_model: true

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq true
      end
    end
  end

  describe "cached_in_model" do
    let(:test_method) { :cached_in_model }

    it_behaves_like "saves cached_in_model"
  end

  describe "cached_in_model?" do
    let(:test_method) { :cached_in_model? }

    it_behaves_like "saves cached_in_model"
  end

  RSpec.shared_examples "saves setting" do |setting_name|
    let(:alt_tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", setting_name => true }

    context "configuration true" do
      around(:each) do |example_proxy|
        orig_setting = ActsAsTaggableOnMongoid.configuration.public_send(setting_name)

        begin
          ActsAsTaggableOnMongoid.configuration.public_send("#{setting_name}=", true)
          example_proxy.run
        ensure
          ActsAsTaggableOnMongoid.configuration.public_send("#{setting_name}=", orig_setting)
        end
      end

      it "returns configuration if not set" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq true
      end

      it "returns false if set false" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", setting_name => false

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq false
      end
    end

    context "configuration false" do
      around(:each) do |example_proxy|
        orig_setting = ActsAsTaggableOnMongoid.configuration.public_send(setting_name)

        begin
          ActsAsTaggableOnMongoid.configuration.public_send("#{setting_name}=", false)
          example_proxy.run
        ensure
          ActsAsTaggableOnMongoid.configuration.public_send("#{setting_name}=", orig_setting)
        end
      end

      it "returns configuration if not set" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq false
      end

      it "returns true if set true" do
        tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", setting_name => true

        expect(alt_tag_definition.public_send(test_method)).to eq true
        expect(tag_definition.public_send(test_method)).to eq true
      end
    end
  end

  RSpec.shared_examples "mirrors configured setting" do |setting_name|
    describe setting_name do
      let(:test_method) { setting_name.to_sym }

      it_behaves_like "saves setting", setting_name
    end

    describe "#{setting_name}?" do
      let(:test_method) { "#{setting_name}?".to_sym }

      it_behaves_like "saves setting", setting_name
    end
  end

  it_behaves_like "mirrors configured setting", :force_lowercase
  it_behaves_like "mirrors configured setting", :force_parameterize
  it_behaves_like "mirrors configured setting", :remove_unused_tags
  it_behaves_like "mirrors configured setting", :preserve_tag_order

  # :default_parser,
  # :tags_table,
  # :taggings_table,

  describe "parser" do
    it "returns default_parser if not set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

      expect(tag_definition.parser).to eq ActsAsTaggableOnMongoid::DefaultParser
    end

    it "returns parser if set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                parser: ActsAsTaggableOnMongoid::GenericParser

      expect(tag_definition.parser).to eq ActsAsTaggableOnMongoid::GenericParser
    end
  end

  describe "tags_table" do
    it "returns Tags if not set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

      expect(tag_definition.tags_table).to eq ActsAsTaggableOnMongoid::Models::Tag
    end

    it "returns tags if set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                tags_table: AltTag

      expect(tag_definition.tags_table).to eq AltTag
    end
  end

  describe "taggings_table" do
    it "returns Taggings if not set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

      expect(tag_definition.taggings_table).to eq ActsAsTaggableOnMongoid::Models::Tagging
    end

    it "returns taggins if set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                taggings_table: AltTagging

      expect(tag_definition.taggings_table).to eq AltTagging
    end
  end

  describe "default" do
    it "returns nil if not set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

      expect(tag_definition.default).to eq []
    end

    it "returns value if set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", default: "Shazam, Black Adam"

      expect(tag_definition.default).to eq(["Shazam", "Black Adam"])
      expect(tag_definition.default).to be_a(ActsAsTaggableOnMongoid::TagList)
    end

    it "does not parse the default if specified not to" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                default: ["Shazam, Black Adam", parse: false]

      expect(tag_definition.default).to eq(["Shazam, Black Adam"])
    end

    it "uses the parser for the default if specified" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                default: ["\"Shazam\", 'Black Adam'",
                                                                                          parser: ActsAsTaggableOnMongoid::GenericParser]

      expect(tag_definition.default).to eq(["\"Shazam\"", "'Black Adam'"])
    end
  end

  describe "tagger" do
    it "supports not being set" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags"

      expect(tag_definition.tagger?).to be_falsey
      expect(tag_definition.default_tagger_method).to be_nil
      expect(tag_definition.tag_list_uses_default_tagger?).to be_falsey
    end

    it "supports true" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", tagger: true

      expect(tag_definition.tagger?).to be_truthy
      expect(tag_definition.default_tagger_method).to be_nil
      expect(tag_definition.tag_list_uses_default_tagger?).to be_falsey
    end

    it "accepts default_tagger" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                tagger: { default_tagger: :owner_method }

      expect(tag_definition.tagger?).to be_truthy
      expect(tag_definition.default_tagger_method).to eq :owner_method
      expect(tag_definition.tag_list_uses_default_tagger?).to be_falsey
    end

    it "does not accept just tag_list_uses_default_tagger" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags",
                                                                                tagger: { tag_list_uses_default_tagger: true }

      expect(tag_definition.tagger?).to be_truthy
      expect(tag_definition.default_tagger_method).to be_nil
      expect(tag_definition.tag_list_uses_default_tagger?).to be_falsey
    end

    it "accepts default_tagger and tag_list_uses_default_tagger" do
      tag_definition = ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                                                "tags",
                                                                                tagger: { default_tagger:               :owner_method,
                                                                                          tag_list_uses_default_tagger: true }

      expect(tag_definition.tagger?).to be_truthy
      expect(tag_definition.default_tagger_method).to eq :owner_method
      expect(tag_definition.tag_list_uses_default_tagger?).to be_truthy
    end
  end
end
