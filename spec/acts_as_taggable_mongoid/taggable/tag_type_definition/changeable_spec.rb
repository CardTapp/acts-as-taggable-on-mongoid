# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Changeable do
  RSpec.shared_examples "it adds changeable methods to a taggable object" do |attribute_list|
    let(:taggable) { TaggableModel.create! name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }
    let(:new_taggable) { TaggableModel.new name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }

    context "with a default" do
      around(:each) do |example_proxy|
        tag_name       = attribute_list.to_s[0..-6].pluralize
        tag_definition = TaggableModel.tag_types[tag_name]

        begin
          tag_definition.instance_variable_set :@default,
                                               ActsAsTaggableOnMongoid::TagList.new(tag_definition, "Shazam, Black Adam", parse: true)

          example_proxy.run
        ensure
          tag_definition.instance_variable_set :@default, ActsAsTaggableOnMongoid::TagList.new(tag_definition)
        end
      end

      describe "#{attribute_list}_change" do
        it "returns nil for an unchanged value" do
          expect(taggable.public_send("#{attribute_list}_change")).to be_nil
        end

        it "new_record returns change array" do
          expect(new_taggable.public_send("#{attribute_list}_change")).
              to eq [["Shazam", "Black Adam"], %w[Solomon Achilles Zeus Atlas Mercury Hercules]]
        end

        it "new_record returns nil if value not set" do
          new_rec = TaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_change")).to be_nil
        end
      end

      describe "#{attribute_list}_changed?" do
        it "returns false for an unchanged value" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
        end

        it "new_record returns true" do
          expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq true
        end

        it "new_record returns false if value not set" do
          new_rec = TaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_changed?")).to eq false
        end
      end

      describe "#{attribute_list}_was" do
        it "returns the previous value" do
          taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

          expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        end

        it "new_record returns the default" do
          expect(new_taggable.public_send("#{attribute_list}_was")).to eq ["Shazam", "Black Adam"]
        end

        it "new_record returns the default" do
          new_rec = TaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_was")).to eq ["Shazam", "Black Adam"]
        end

        it "returns the previous value even if several changes" do
          taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")
          taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

          expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        end

        it "returns the current value if it hasn't changed" do
          expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        end
      end

      describe "reset_#{attribute_list}_to_default!" do
        it "changes the value to default" do
          taggable.public_send("reset_#{attribute_list}_to_default!")

          expect(taggable.public_send(attribute_list)).to eq ["Shazam", "Black Adam"]
        end

        it "new_record changes the value to default" do
          new_taggable.public_send("reset_#{attribute_list}_to_default!")

          expect(new_taggable.public_send(attribute_list)).to eq ["Shazam", "Black Adam"]
        end
      end
    end

    context "preserve_tag_order" do
      around(:each) do |example_proxy|
        tag_name                  = attribute_list.to_s[0..-6].pluralize
        tag_definition            = TaggableModel.tag_types[tag_name]
        previous_setting          = ActsAsTaggableOnMongoid.preserve_tag_order?
        taggable_previous_setting = tag_definition.preserve_tag_order?

        begin
          ActsAsTaggableOnMongoid.preserve_tag_order = true
          tag_definition.instance_variable_set :@preserve_tag_order, true

          example_proxy.run
        ensure
          ActsAsTaggableOnMongoid.preserve_tag_order = previous_setting
          tag_definition.instance_variable_set :@preserve_tag_order, taggable_previous_setting
        end
      end

      describe "#{attribute_list}_change" do
        it "returns change if only order changed" do
          taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

          expect(taggable.public_send("#{attribute_list}_change")).
              to eq [%w[Solomon Hercules Atlas Zeus Achilles Mercury], %w[Solomon Achilles Zeus Atlas Mercury Hercules]]
        end

        it "returns nil if changed then changed back" do
          taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")
          taggable.public_send("#{attribute_list}=", "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury")

          expect(taggable.public_send("#{attribute_list}_change")).to be_nil
        end
      end

      describe "#{attribute_list}_changed?" do
        it "returns true if only order changed" do
          taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

          expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
        end

        it "returns false if changed then changed back" do
          taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")
          taggable.public_send("#{attribute_list}=", "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury")

          expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
        end
      end
    end

    describe "#{attribute_list}?" do
      it "returns true if set" do
        expect(taggable.public_send("#{attribute_list}?")).to eq true
      end

      it "returns false if not set" do
        taggable.public_send("#{attribute_list}=", nil)

        expect(taggable.public_send("#{attribute_list}?")).to eq false
      end
    end

    describe "#{attribute_list}_change" do
      it "returns nil if not changed" do
        expect(taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "returns nil if changed then changed back in different order" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

        expect(taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "returns change array if changed" do
        taggable.public_send("#{attribute_list}=", "Shazam")
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

        expect(taggable.public_send("#{attribute_list}_change")).
            to eq [%w[Solomon Hercules Atlas Zeus Achilles Mercury], %w[Shu Heru Amon Zehuti Aton Mehen]]
      end

      it "new_record returns nil if changed then changed back in different order" do
        new_taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        new_taggable.public_send("#{attribute_list}=", nil)

        expect(new_taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "new_record returns change array if changed" do
        expect(new_taggable.public_send("#{attribute_list}_change")).
            to eq [[], %w[Solomon Hercules Atlas Zeus Achilles Mercury]]
      end
    end

    describe "#{attribute_list}_changed?" do
      it "returns false if it hasn't changed" do
        expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
      end

      it "new_record returns true if it has changed" do
        expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns false if changed then changed back in different order" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
      end

      it "new_record returns false if changed then changed back in different order" do
        new_taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        new_taggable.public_send("#{attribute_list}=", nil)

        expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq false
      end

      it "returns true if it has changed" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns true if it has changed via add" do
        taggable.public_send(attribute_list).add "Shu, Heru, Amon, Zehuti, Aton, Mehen", parse: true

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns true if it has changed via <<" do
        taggable.public_send(attribute_list) << ["Shu, Heru, Amon, Zehuti, Aton, Mehen", parse: true]

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns true if it has changed via concat" do
        taggable.public_send(attribute_list).concat %w[Shu Heru Amon Zehuti Aton Mehen"]

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns true if it has changed via remove" do
        taggable.public_send(attribute_list).remove "Solomon"

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "new_record returns true if it has changed" do
        expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq true
      end
    end

    describe "#{attribute_list}_will_change!" do
      it "adds #{attribute_list}_will_change!" do
        expect(taggable).to receive(:attribute_wil_change!).with attribute_list.to_s

        taggable.public_send("#{attribute_list}_will_change!")
      end
    end

    describe "#{attribute_list}_changed_from_default?" do
      it "is true if it isn't blank" do
        expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to eq true
        expect(new_taggable.public_send("#{attribute_list}_changed_from_default?")).to eq true
      end

      it "returns false if it is blank" do
        taggable.public_send("#{attribute_list}=", nil)

        expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to eq false
      end
    end

    describe "#{attribute_list}_was" do
      it "returns the previous value" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

        expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
      end

      it "new_record returns the default" do
        expect(new_taggable.public_send("#{attribute_list}_was")).to be_blank
      end

      it "returns the previous value even if several changes" do
        taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

        expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
      end

      it "returns the current value if it hasn't changed" do
        expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
      end
    end

    describe "reset_#{attribute_list}!" do
      it "changes the value back to the initial value" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

        taggable.public_send("reset_#{attribute_list}!")

        expect(taggable.public_send(attribute_list)).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
      end

      it "new_record reset_#{attribute_list}! changes the value to default" do
        new_taggable.public_send("reset_#{attribute_list}!")

        expect(new_taggable.public_send(attribute_list)).to be_blank
      end
    end

    describe "reset_#{attribute_list}_to_default!" do
      it "changes the value to []" do
        taggable.public_send("reset_#{attribute_list}_to_default!")

        expect(taggable.public_send(attribute_list)).to be_blank
      end
    end
  end

  it_behaves_like "it adds changeable methods to a taggable object", :tag_list
  it_behaves_like "it adds changeable methods to a taggable object", :language_list
  it_behaves_like "it adds changeable methods to a taggable object", :skill_list
  it_behaves_like "it adds changeable methods to a taggable object", :need_list
  it_behaves_like "it adds changeable methods to a taggable object", :offering_list
end
