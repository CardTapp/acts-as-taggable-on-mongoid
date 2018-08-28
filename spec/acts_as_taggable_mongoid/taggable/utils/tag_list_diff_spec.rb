# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff do
  # let!(:all_taggable) do
  #   TaggableModel.create! name:     "Billy Batson",
  #                         tag_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury, Shu, Heru, Amon, Zehuti, Aton, Mehen"
  # end
  # let(:taggable) { TaggableModel.create! name: "Billy Batson", tag_list: "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }
  # let(:new_tags) { %w[Solomon Hercules Atlas Mercury Zeus Shu Heru Amon Zehuti Aton Mehen] }
  # let(:current_tags) do
  #   taggable.send(:tags_on, tag_definition).map(&:tag).compact
  # end
  # let(:tags) do
  #   new_tags.map do |tag|
  #     ActsAsTaggableOnMongoid::Models::Tag.where(name: tag).first
  #   end
  # end
  # let(:mixed_tags) { [tags.last] | tags.sample(1_000) }
  #
  # context "preserve_tag_order?" do
  #   let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", preserve_tag_order: true }
  #
  #   describe "call" do
  #     it "new_tags returns existing tags if they are in a differnt order with new tags" do
  #       tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition, tags: tags, current_tags: current_tags)
  #
  #       tag_diff.call
  #
  #       expect(tag_diff.new_tags.map(&:name)).to eq %w[Mercury Zeus Shu Heru Amon Zehuti Aton Mehen]
  #     end
  #
  #     it "old_tags returns deleted and existing tags which changed order" do
  #       tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition, tags: tags, current_tags: current_tags)
  #
  #       tag_diff.call
  #
  #       expect(tag_diff.old_tags.map(&:name)).to eq %w[Achilles Zeus Mercury]
  #     end
  #
  #     it "new_tags returns no tags if all orders changed" do
  #       tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition,
  #                                                                            tags:           mixed_tags,
  #                                                                            current_tags:   current_tags)
  #
  #       tag_diff.call
  #
  #       expect(tag_diff.new_tags.map(&:name).sort).to eq new_tags.sort
  #     end
  #
  #     it "old_tags returns all tags if all orders changed" do
  #       tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition,
  #                                                                            tags:           mixed_tags,
  #                                                                            current_tags:   current_tags)
  #
  #       tag_diff.call
  #
  #       expect(tag_diff.old_tags.map(&:name)).to eq %w[Achilles Solomon Hercules Atlas Zeus Mercury]
  #     end
  #   end
  # end
  #
  # context "do not preserve_tag_order?" do
  #   let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new TaggableModel, "tags", preserve_tag_order: false }
  #
  #   it "new_tags returns only new tags even if they are in a differnt order" do
  #     tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition, tags: tags, current_tags: current_tags)
  #
  #     tag_diff.call
  #
  #     expect(tag_diff.new_tags.map(&:name)).to eq %w[Shu Heru Amon Zehuti Aton Mehen]
  #   end
  #
  #   it "old_tags returns only deleted tags even if they are in a differnt order" do
  #     tag_diff = ActsAsTaggableOnMongoid::Taggable::Utils::TagListDiff.new(tag_definition: tag_definition, tags: tags, current_tags: current_tags)
  #
  #     tag_diff.call
  #
  #     expect(tag_diff.old_tags.map(&:name)).to eq %w[Achilles]
  #   end
  # end
end
