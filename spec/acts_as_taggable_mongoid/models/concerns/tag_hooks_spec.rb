# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Models::Concerns::TagHooks do
  context "owned tags" do
    context "cached" do
      let(:owner) { MyUser.create name: "My User" }
      let(:other_owner) { MyUser.create name: "Other User" }
      let!(:taggable) { CachedTaggerTaggableModel.create my_user: owner, need_list: "keep, change, do not change" }
      let!(:also_taggable) { CachedTaggerTaggableModel.create my_user: owner, need_list: "also keep, change, do not change" }
      let!(:no_change_taggable) { CachedTaggerTaggableModel.create my_user: owner, need_list: "keep too, do not change" }
      let!(:other_taggable) { CachedTaggerTaggableModel.create my_user: other_owner, need_list: "keep, change, do not change" }
      let!(:other_also_taggable) { CachedTaggerTaggableModel.create my_user: other_owner, need_list: "also keep, change, do not change" }
      let(:tag) { owner.owned_tags.where(name: "change").first }

      describe "update" do
        it "updates the tag_name in taggings" do
          tag.update_attributes! name: "keep change"

          tag.reload.taggings.each do |tagging|
            expect(tagging.tag_name).to eq "keep change"
          end
        end

        it "updates the cached tag list only for this owner" do
          tag.update_attributes! name: "keep change"

          expect(taggable.reload.need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(taggable.cached_need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(also_taggable.cached_need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
          expect(no_change_taggable.cached_need_list.sort).to eq ["keep too", "do not change"].sort

          expect(other_taggable.reload.need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_taggable.cached_need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_also_taggable.reload.need_list.sort).to eq ["also keep", "change", "do not change"].sort
          expect(other_also_taggable.cached_need_list.sort).to eq ["also keep", "change", "do not change"].sort
        end
      end

      describe "destroy" do
        it "destroys the taggings" do
          tag.destroy

          expect(ActsAsTaggableOnMongoid::Models::Tagging.where(tag_id: tag.id).count).to be_zero
        end

        it "removes from the cached tag list only for this owner" do
          tag.destroy

          expect(taggable.reload.need_list.sort).to eq ["keep", "do not change"].sort
          expect(taggable.cached_need_list.sort).to eq ["keep", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "do not change"].sort
          expect(also_taggable.cached_need_list.sort).to eq ["also keep", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
          expect(no_change_taggable.cached_need_list.sort).to eq ["keep too", "do not change"].sort

          expect(other_taggable.reload.need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_taggable.cached_need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_also_taggable.reload.need_list.sort).to eq ["also keep", "change", "do not change"].sort
          expect(other_also_taggable.cached_need_list.sort).to eq ["also keep", "change", "do not change"].sort
        end
      end
    end

    context "not cached" do
      let(:owner) { MyUser.create name: "My User" }
      let(:other_owner) { MyUser.create name: "Other User" }
      let!(:taggable) { TaggerTaggableModel.create my_user: owner, need_list: "keep, change, do not change" }
      let!(:also_taggable) { TaggerTaggableModel.create my_user: owner, need_list: "also keep, change, do not change" }
      let!(:no_change_taggable) { TaggerTaggableModel.create my_user: owner, need_list: "keep too, do not change" }
      let!(:other_taggable) { TaggerTaggableModel.create my_user: other_owner, need_list: "keep, change, do not change" }
      let!(:other_also_taggable) { TaggerTaggableModel.create my_user: other_owner, need_list: "also keep, change, do not change" }
      let(:tag) { owner.owned_tags.where(name: "change").first }

      describe "update" do
        it "updates the tag_name in taggings" do
          tag.update_attributes! name: "keep change"

          tag.reload.taggings.each do |tagging|
            expect(tagging.tag_name).to eq "keep change"
          end
        end

        it "updates the cached tag list only for this owner" do
          tag.update_attributes! name: "keep change"

          expect(taggable.reload.need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort

          expect(other_taggable.reload.need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_also_taggable.reload.need_list.sort).to eq ["also keep", "change", "do not change"].sort
        end
      end

      describe "destroy" do
        it "destroys the taggings" do
          tag.destroy

          expect(ActsAsTaggableOnMongoid::Models::Tagging.where(tag_id: tag.id).count).to be_zero
        end

        it "removes from the cached tag list only for this owner" do
          tag.destroy

          expect(taggable.reload.need_list.sort).to eq ["keep", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort

          expect(other_taggable.reload.need_list.sort).to eq ["keep", "change", "do not change"].sort
          expect(other_also_taggable.reload.need_list.sort).to eq ["also keep", "change", "do not change"].sort
        end
      end
    end
  end

  context "unowned tags" do
    let(:tag) { ActsAsTaggableOnMongoid::Models::Tag.where(name: "change").first }

    context "cached" do
      let!(:taggable) { CachedTaggableModel.create need_list: "keep, change, do not change" }
      let!(:also_taggable) { CachedTaggableModel.create need_list: "also keep, change, do not change" }
      let!(:no_change_taggable) { CachedTaggableModel.create need_list: "keep too, do not change" }

      describe "update" do
        it "updates the tag_name in taggings" do
          tag.update_attributes! name: "keep change"

          tag.reload.taggings.each do |tagging|
            expect(tagging.tag_name).to eq "keep change"
          end
        end

        it "updates the cached tag list only for this owner" do
          tag.update_attributes! name: "keep change"

          expect(taggable.reload.need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(taggable.cached_need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(also_taggable.cached_need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
          expect(no_change_taggable.cached_need_list.sort).to eq ["keep too", "do not change"].sort
        end
      end

      describe "destroy" do
        it "destroys the taggings" do
          tag.destroy

          expect(ActsAsTaggableOnMongoid::Models::Tagging.where(tag_id: tag.id).count).to be_zero
        end

        it "removes from the cached tag list only for this owner" do
          tag.destroy

          expect(taggable.reload.need_list.sort).to eq ["keep", "do not change"].sort
          expect(taggable.cached_need_list.sort).to eq ["keep", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "do not change"].sort
          expect(also_taggable.cached_need_list.sort).to eq ["also keep", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
          expect(no_change_taggable.cached_need_list.sort).to eq ["keep too", "do not change"].sort
        end
      end
    end

    context "not cached" do
      let!(:taggable) { TaggableModel.create need_list: "keep, change, do not change" }
      let!(:also_taggable) { TaggableModel.create need_list: "also keep, change, do not change" }
      let!(:no_change_taggable) { TaggableModel.create need_list: "keep too, do not change" }

      describe "update" do
        it "updates the tag_name in taggings" do
          tag.update_attributes! name: "keep change"

          tag.reload.taggings.each do |tagging|
            expect(tagging.tag_name).to eq "keep change"
          end
        end

        it "updates the cached tag list" do
          tag.update_attributes! name: "keep change"

          expect(taggable.reload.need_list.sort).to eq ["keep", "keep change", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "keep change", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
        end
      end

      describe "destroy" do
        it "destroys the taggings" do
          tag.destroy

          expect(ActsAsTaggableOnMongoid::Models::Tagging.where(tag_id: tag.id).count).to be_zero
        end

        it "removes from the cached tag list" do
          tag.destroy

          expect(taggable.reload.need_list.sort).to eq ["keep", "do not change"].sort
          expect(also_taggable.reload.need_list.sort).to eq ["also keep", "do not change"].sort
          expect(no_change_taggable.reload.need_list.sort).to eq ["keep too", "do not change"].sort
        end
      end
    end
  end
end
