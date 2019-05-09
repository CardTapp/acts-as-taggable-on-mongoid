# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid do
  let(:taggable) { TaggableModel.new(name: "Bob Jones") }

  it "has a version number" do
    expect(ActsAsTaggableOnMongoid::VERSION).not_to be nil
  end

  it "can create a database record" do
    Tagged.create string_field: "This is a string"

    expect(Tagged.count).to eq 1
  end

  around(:each) do |example_proxy|
    preserve_tag_order = ActsAsTaggableOnMongoid.preserve_tag_order?

    begin
      example_proxy.run
    ensure
      ActsAsTaggableOnMongoid.preserve_tag_order = preserve_tag_order

      TaggableModel.tag_types.delete_if do |key, _definition|
        key == "inserted_ordered_tags"
      end
    end
  end

  describe "Taggable Method Generation To Preserve Order" do
    before(:each) do
      ActsAsTaggableOnMongoid.preserve_tag_order = false

      TaggableModel.acts_as_ordered_taggable_on(:inserted_ordered_tags)
    end

    it "should respond 'true' to preserve_tag_order?" do
      expect(TaggableModel.tag_types[:inserted_ordered_tags].preserve_tag_order?).to be_truthy
    end
  end

  describe "Taggable Method Generation" do
    it "should create a class attribute for tag types" do
      expect(taggable.class).to respond_to(:tag_types)
    end

    it "should create an instance attribute for tag types" do
      expect(taggable).to respond_to(:tag_types)
    end

    it "should have all tag types" do
      expect(taggable.tag_types.keys).to eq(%w[tags languages skills needs offerings])
      expect(AlteredInheritingTaggableModel.tag_types.keys).to eq(%w[tags languages skills needs offerings parts])
    end

    it "should generate an association for each tag type" do
      expect(taggable).to respond_to(:tags, :skills, :languages)
    end

    # TODO: Not implemented yet
    xit "should add tag_counts to singleton" do
      expect(TaggableModel).to respond_to(:tag_counts)
    end

    it "should add tagged_with to singleton" do
      expect(TaggableModel).to respond_to(:tagged_with)
    end

    it "should generate a tag_list accessor/setter for each tag type" do
      expect(taggable).to respond_to(:tag_list, :skill_list, :language_list)
      expect(taggable).to respond_to(:tag_list=, :skill_list=, :language_list=)
    end

    it "should generate a tag_list accessor, that includes owned tags, for each tag type" do
      expect(taggable).to respond_to(:all_tags_list, :all_skills_list, :all_languages_list)
    end
  end

  describe "Reloading" do
    it "should save a model instantiated by Model.find" do
      taggable       = TaggableModel.create!(name: "Taggable")
      found_taggable = TaggableModel.find(taggable.id)
      found_taggable.save
    end
  end

  describe "Matching Contexts" do
    # TODO: Not implemented yet
    xit "should find objects with tags of matching contexts" do
      taggable_one = TaggableModel.create!(name: "Taggable 1")
      taggable_two = TaggableModel.create!(name: "Taggable 2")
      taggable_three = TaggableModel.create!(name: "Taggable 3")

      taggable_one.offering_list = "one, two"
      taggable_one.save!

      taggable_two.need_list = "one, two"
      taggable_two.save!

      taggable_three.offering_list = "one, two"
      taggable_three.save!

      expect(taggable_one.find_matching_contexts(:offerings, :needs)).to include(taggable_two)
      expect(taggable_one.find_matching_contexts(:offerings, :needs)).to_not include(taggable_three)
    end

    # TODO: Not implemented yet
    xit "should find other related objects with tags of matching contexts" do
      taggable_one = TaggableModel.create!(name: "Taggable 1")
      taggable_two = OtherTaggableModel.create!(name: "Taggable 2")
      taggable_three = OtherTaggableModel.create!(name: "Taggable 3")

      taggable_one.offering_list = "one, two"
      taggable_one.save

      taggable_two.need_list = "one, two"
      taggable_two.save

      taggable_three.offering_list = "one, two"
      taggable_three.save

      expect(taggable_one.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs)).to include(taggable_two)
      expect(taggable_one.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs)).to_not include(taggable_three)
    end

    # TODO: Not implemented yet
    xit "should not include the object itself in the list of related objects with tags of matching contexts" do
      taggable_one = TaggableModel.create!(name: "Taggable 1")
      taggable_two = TaggableModel.create!(name: "Taggable 2")

      taggable_one.offering_list = "one, two"
      taggable_one.need_list     = "one, two"
      taggable_one.save

      taggable_two.need_list = "one, two"
      taggable_two.save

      expect(taggable_one.find_matching_contexts_for(TaggableModel, :offerings, :needs)).to include(taggable_two)
      expect(taggable_one.find_matching_contexts_for(TaggableModel, :offerings, :needs)).to_not include(taggable_one)
    end

    # TODO: Not implemented yet
    xit "should ensure joins to multiple taggings maintain their contexts when aliasing" do
      taggable_one = TaggableModel.create!(name: "Taggable 1")

      taggable_one.offering_list = "one"
      taggable_one.need_list     = "two"

      taggable_one.save

      column      = TaggableModel.connection.quote_column_name("context")
      offer_alias = TaggableModel.connection.quote_table_name(ActsAsTaggableOnMongoid.taggings_table)
      need_alias  = TaggableModel.connection.quote_table_name("need_taggings_taggable_models_join")

      expect(TaggableModel.joins(:offerings, :needs).to_sql).to include "#{offer_alias}.#{column}"
      expect(TaggableModel.joins(:offerings, :needs).to_sql).to include "#{need_alias}.#{column}"
    end
  end

  describe "Tagging Contexts" do
    around(:each) do |example_proxy|
      begin
        example_proxy.run
      ensure
        TaggableModel.tag_types.delete(:array)
      end
    end

    it "should not contain embedded/nested arrays" do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      expect(TaggableModel.tag_types[:array]).to be
    end

    it "should _flatten_ the content of arrays" do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      expect(TaggableModel.tag_types[:array]).to be
    end

    it "should not raise an error when passed nil" do
      expect { TaggableModel.acts_as_taggable_on }.to_not raise_error
    end

    it "should not raise an error when passed [nil]" do
      expect { TaggableModel.acts_as_taggable_on([nil]) }.to_not raise_error
    end

    # TODO: Not implemented yet
    xit "should include dynamic contexts in tagging_contexts" do
      taggable = TaggableModel.create!(name: "Dynamic Taggable")
      taggable.set_tag_list_on :colors, "tag1, tag2, tag3"
      expect(taggable.tagging_contexts).to eq(%w[tags languages skills needs offerings array colors])
      taggable.save
      taggable = TaggableModel.where(name: "Dynamic Taggable").first
      expect(taggable.tagging_contexts).to eq(%w[tags languages skills needs offerings array colors])
    end
  end

  # context "when tagging context ends in an "s" when singular (ex. "status", "glass", etc.)" do
  #   describe "caching" do
  #     before { taggable = OtherCachedModel.new(name: "John Smith") }
  #     subject { taggable }
  #
  #     it { should respond_to(:save_cached_tag_list) }
  #     its(:cached_language_list) { should be_blank }
  #     its(:cached_status_list) { should be_blank }
  #     its(:cached_glass_list) { should be_blank }
  #
  #     context "language taggings cache after update" do
  #       before { taggable.update_attributes(language_list: "ruby, .net") }
  #       subject { taggable }
  #
  #       its(:language_list) { should == ["ruby", ".net"] }
  #       its(:cached_language_list) { should == "ruby, .net" } # passes
  #       its(:instance_variables) { should include((RUBY_VERSION < "1.9" ? "language_list" : :language_list)) }
  #     end
  #
  #     context "status taggings cache after update" do
  #       before { taggable.update_attributes(status_list: "happy, married") }
  #       subject { taggable }
  #
  #       its(:status_list) { should == ["happy", "married"] }
  #       its(:cached_status_list) { should == "happy, married" } # fails
  #       its(:cached_status_list) { should_not == "" } # fails, is blank
  #       its(:instance_variables) { should include((RUBY_VERSION < "1.9" ? "status_list" : :status_list)) }
  #       its(:instance_variables) { should_not include((RUBY_VERSION < "1.9" ? "statu_list" : :statu_list)) } # fails, note: one "s"
  #
  #     end
  #
  #     context "glass taggings cache after update" do
  #       before do
  #         taggable.update_attributes(glass_list: "rectangle, aviator")
  #       end
  #
  #       subject { taggable }
  #       its(:glass_list) { should == ["rectangle", "aviator"] }
  #       its(:cached_glass_list) { should == "rectangle, aviator" } # fails
  #       its(:cached_glass_list) { should_not == "" } # fails, is blank
  #       if RUBY_VERSION < "1.9"
  #         its(:instance_variables) { should include("glass_list") }
  #         its(:instance_variables) { should_not include("glas_list") } # fails, note: one "s"
  #       else
  #         its(:instance_variables) { should include(:glass_list) }
  #         its(:instance_variables) { should_not include(:glas_list) } # fails, note: one "s"
  #       end
  #
  #     end
  #   end
  # end

  describe "taggings" do
    let(:taggable) { TaggableModel.new(name: "Art Kram") }

    it "should return no taggings" do
      expect(taggable.taggings).to be_empty
    end
  end

  describe "remove_unused_tags" do
    let!(:taggable) { TaggableModel.create!(name: "Bob Jones", tag_list: "awesome") }
    let!(:tag) { ActsAsTaggableOnMongoid::Models::Tag.where(name: "awesome").first }
    let!(:tagging) { ActsAsTaggableOnMongoid::Models::Tagging.where(tag_name: "awesome").first }

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

    context "if set to true" do
      before do
        TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, true
      end

      it "should remove unused tags after removing taggings" do
        tagging.destroy
        expect(ActsAsTaggableOnMongoid::Models::Tag.where(name: "awesome").first).not_to be
      end
    end

    context "if set to false" do
      before do
        TaggableModel.tag_types[:tags].instance_variable_set :@remove_unused_tags, false
      end

      it "should not remove unused tags after removing taggings" do
        tagging.destroy
        expect(ActsAsTaggableOnMongoid::Models::Tag.where(name: "awesome").first).to eq(tag)
      end
    end
  end
end
