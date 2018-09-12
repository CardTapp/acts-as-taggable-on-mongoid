# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dirty behavior of taggable objects" do
  context "with un-contexted tags" do
    let!(:taggable) { TaggableModel.create(tag_list: "awesome, epic") }

    context "when tag_list changed" do
      before(:each) do
        expect(taggable.changes).to be_empty
        taggable.tag_list = "one"
      end

      it "should show changes of dirty object" do
        expect(taggable.changes).to eq("tag_list" => [%w[awesome epic], ["one"]])
      end

      it "should show changes of freshly initialized dirty object" do
        found_taggable          = TaggableModel.find(taggable.id)
        found_taggable.tag_list = "one"

        expect(found_taggable.changes).to eq("tag_list" => [%w[awesome epic], ["one"]])
      end

      # if Rails.version >= "5.1"
      #   it "flags tag_list as changed" do
      #     expect(taggable.will_save_change_to_tag_list?).to be_truthy
      #   end
      # end

      it "preserves original value" do
        expect(taggable.tag_list_was).to eq(%w[awesome epic])
      end

      it "shows what the change was" do
        expect(taggable.tag_list_change).to eq([%w[awesome epic], ["one"]])
      end

      context "without order" do
        it "should not mark attribute if order change " do
          taggable          = TaggableModel.create(name: "Dirty Harry", tag_list: %w[d c b a])
          taggable.tag_list = %w[a b c d]
          expect(taggable.tag_list_changed?).to be_falsey
        end
      end

      context "with order" do
        it "should mark attribute if order change" do
          taggable = OrderedTaggableModel.create(name: "Clean Harry", tag_list: "d,c,b,a")
          taggable.save
          taggable.tag_list = %w[a b c d]
          expect(taggable.tag_list_changed?).to be_truthy
        end
      end
    end

    context "when tag_list is the same" do
      before(:each) do
        taggable.tag_list = "awesome, epic"
      end

      it "is not flagged as changed" do
        expect(taggable.tag_list_changed?).to be_falsy
      end

      it "does not show any changes to the taggable item" do
        expect(taggable.changes).to be_empty
      end

      it "does not show any changes to the taggable item when using array assignments" do
        taggable.tag_list = %w[awesome epic]
        expect(taggable.changes).to be_empty
      end
    end
  end

  context "with context tags" do
    let!(:taggable) { TaggableModel.create("language_list" => "awesome, epic") }

    context "when language_list changed" do
      before(:each) do
        expect(taggable.changes).to be_empty
        taggable.language_list = "one"
      end

      it "should show changes of dirty object" do
        expect(taggable.changes).to eq("language_list" => [%w[awesome epic], ["one"]])
      end

      it "flags language_list as changed" do
        expect(taggable.language_list_changed?).to be_truthy
      end

      it "preserves original value" do
        expect(taggable.language_list_was).to eq(%w[awesome epic])
      end

      it "shows what the change was" do
        expect(taggable.language_list_change).to eq([%w[awesome epic], ["one"]])
      end
    end

    context "when language_list is the same" do
      before(:each) do
        taggable.language_list = "awesome, epic"
      end

      it "is not flagged as changed" do
        expect(taggable.language_list_changed?).to be_falsy
      end

      it "does not show any changes to the taggable item" do
        expect(taggable.changes).to be_empty
      end
    end

    context "when language_list changed by association" do
      it "flags language_list as changed" do
        expect(taggable.changes).to be_empty
        taggable.language_list << "one"
        expect(taggable.language_list_changed?).to be_truthy
      end
    end
  end
end
