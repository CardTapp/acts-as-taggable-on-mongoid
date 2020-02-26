# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::Cache do
  # A test class for testing cacheed_in_model tags
  class CacheTaggableModel
    include ::Mongoid::Document
    include ::Mongoid::Timestamps

    field :name, type: String

    # :reek:UtilityFunction
    def my_user
      MyUser.find_or_create_by! name: "My User"
    end
  end

  after(:each) do
    CacheTaggableModel.tag_types.clear
  end

  let(:my_user) { MyUser.find_or_create_by! name: "My User" }
  let(:other_user) { MyUser.find_or_create_by! name: "Other User" }

  it "caches the field defaults" do
    CacheTaggableModel.acts_as_taggable cached_in_model: true

    record = CacheTaggableModel.create! tag_list: "A, tag, \"list, of\", words"
    record.reload

    expect(record.cached_tag_list.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@tag_list)).to be_blank
  end

  it "caches the field in a named field" do
    CacheTaggableModel.acts_as_taggable_on :groups, cached_in_model: { field: :tag_list_cache_field }

    record = CacheTaggableModel.create! group_list: "A, tag, \"list, of\", words"
    record.reload

    expect(record.tag_list_cache_field.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@group_list)).to be_blank
  end

  it "caches the field as a string" do
    CacheTaggableModel.acts_as_taggable_on :string_tags, cached_in_model: { as_list: false }

    record = CacheTaggableModel.create! string_tag_list: "A, tag, \"list, of\", words"
    record.reload

    expect(record.cached_string_tag_list).to eq "\"list, of\",A,tag,words"
    expect(record.instance_variable_get(:@string_tag_list)).to be_blank

    expect(record.string_tag_list.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@string_tag_list)).to be
  end

  it "caches multiple owners as a string" do
    CacheTaggableModel.acts_as_taggable_on :tagged_tags,
                                           cached_in_model: { field: :tag_list_cache_field, as_list: false },
                                           tagger:          { tag_list_uses_default_tagger: true, default_tagger: :my_user }

    record = CacheTaggableModel.create! tagged_tag_list: "A, tag"
    record.tagger_tagged_tag_list(other_user).add "\"list, of\", words", parse: true
    record.save!
    record.reload

    expect(record.tag_list_cache_field).to eq "A,tag,\"list, of\",words"
    expect(record.instance_variable_get(:@tagged_tag_list)).to be_blank

    expect(record.all_tagged_tags_list.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@tagged_tag_list)).to be
  end

  it "caches multiple owners as an array" do
    CacheTaggableModel.acts_as_taggable_on :lists,
                                           cached_in_model: { field: :tag_list_cache_field },
                                           tagger:          { tag_list_uses_default_tagger: true, default_tagger: :my_user }

    record = CacheTaggableModel.create! list_list: "A, tag"
    record.tagger_list_list(other_user).add "\"list, of\", words", parse: true
    record.save!
    record.reload

    expect(record.tag_list_cache_field.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@list_list)).to be_blank

    expect(record.all_lists_list.sort).to eq ["A", "tag", "list, of", "words"].sort
    expect(record.instance_variable_get(:@list_list)).to be
  end
end
