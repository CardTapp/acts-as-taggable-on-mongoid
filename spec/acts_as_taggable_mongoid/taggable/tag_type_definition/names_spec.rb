# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Names do
  let(:tag_definition) do
    ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel,
                                                             :some_stupid_tags,
                                                             tags_table:     ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition,
                                                             taggings_table: ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff
  end

  it "returns the tag_list_name" do
    expect(tag_definition.tag_list_name).to eq "some_stupid_tag_list"
  end

  it "returns the tag_list_variable_name" do
    expect(tag_definition.tag_list_variable_name).to eq "@some_stupid_tag_list"
  end

  it "returns the all_tag_list_name" do
    expect(tag_definition.all_tag_list_name).to eq "all_some_stupid_tags_list"
  end

  it "returns the all_tag_list_variable_name" do
    expect(tag_definition.all_tag_list_variable_name).to eq "@all_some_stupid_tags_list"
  end

  it "returns the single_tag_type" do
    expect(tag_definition.single_tag_type).to eq "some_stupid_tag"
  end

  it "returns the base_tags_method" do
    expect(tag_definition.base_tags_method).to eq :base_tag_type_definitions
  end

  it "returns the taggings_name" do
    expect(tag_definition.taggings_name).to eq :tag_list_diffs
  end
end
