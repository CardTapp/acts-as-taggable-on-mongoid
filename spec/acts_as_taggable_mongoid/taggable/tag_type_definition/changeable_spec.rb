# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition::Changeable do
  RSpec.shared_examples "it adds changeable methods to a taggable object" do |attribute_list|
    let(:taggable) { TaggableModel.create! name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }
    let(:new_taggable) { TaggableModel.new name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }

    context "with a default" do
      let(:taggable) { DefaultedTaggableModel.create! name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }
      let(:new_taggable) { DefaultedTaggableModel.new name: "Billy Batson", attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury" }

      describe "#{attribute_list}_change" do
        it "returns nil for an unchanged value" do
          expect(taggable.public_send("#{attribute_list}_change")).to be_nil
        end

        it "new_record returns change array" do
          change_array = new_taggable.public_send("#{attribute_list}_change")
          expect(change_array).
              to eq [["Shazam", "Black Adam"], %w[Solomon Achilles Zeus Atlas Mercury Hercules]]
          change_array[0].add "This", "is", "silly"
          change_array[1].add "This", "is", "silly"
          expect(new_taggable.public_send("#{attribute_list}_change")).
              to eq [["Shazam", "Black Adam"], %w[Solomon Achilles Zeus Atlas Mercury Hercules]]
        end

        it "new_record returns nil if value not set" do
          new_rec = DefaultedTaggableModel.new

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
          new_rec = DefaultedTaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_changed?")).to eq false
        end
      end

      describe "#{attribute_list}_was" do
        it "returns the previous value" do
          taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

          was_list = taggable.public_send("#{attribute_list}_was")
          expect(was_list).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
          was_list.add "This", "is", "silly"
          expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        end

        it "new_record returns the default" do
          expect(new_taggable.public_send("#{attribute_list}_was")).to eq ["Shazam", "Black Adam"]
        end

        it "new_record returns the default" do
          new_rec = DefaultedTaggableModel.new

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
        expect(taggable).to receive(:attribute_will_change!).with attribute_list.to_s

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

  RSpec.shared_examples "it adds changeable methods to a taggable object with taggers" do
    let(:my_user) { MyUser.create! name: "My User" }
    let(:other_user) { MyUser.create! name: "Other User" }
    let(:third_user) { MyUser.create! name: "Third User" }
    let(:tag_name) { attribute_list.to_s[0..-6].pluralize }
    let(:taggable) do
      TaggerTaggableModel.create! name: "Billy Batson", my_user: my_user, attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"
    end
    let(:new_taggable) do
      TaggerTaggableModel.new name: "Billy Batson", my_user: my_user, attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"
    end
    let(:old) { ActsAsTaggableOnMongoid::TaggerTagList.new(TaggerTaggableModel.tag_types[tag_name], taggable) }
    let(:new) { ActsAsTaggableOnMongoid::TaggerTagList.new(TaggerTaggableModel.tag_types[tag_name], taggable) }

    context "with a default" do
      let(:taggable) do
        DefaultedTaggerTaggableModel.create! name:          "Billy Batson",
                                             my_user:       my_user,
                                             attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"
      end
      let(:new_taggable) do
        DefaultedTaggerTaggableModel.new name:          "Billy Batson",
                                         my_user:       my_user,
                                         attribute_list => "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"
      end

      describe "<attribute>_change" do
        it "returns nil for an unchanged value" do
          expect(taggable.public_send("#{attribute_list}_change")).to be_nil
        end

        it "new_record returns change array" do
          old = ActsAsTaggableOnMongoid::TaggerTagList.new(DefaultedTaggerTaggableModel.tag_types[tag_name], new_taggable)
          new = ActsAsTaggableOnMongoid::TaggerTagList.new(DefaultedTaggerTaggableModel.tag_types[tag_name], new_taggable)

          old[default_tagger]             = ["Shazam", "Black Adam"]
          new[unspecified_default_tagger] = %w[Solomon Achilles Zeus Atlas Mercury Hercules]

          expect(new_taggable.public_send("#{attribute_list}_change")).to eq [old, new]
        end

        it "new_record returns nil if value not set" do
          new_rec = DefaultedTaggerTaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_change")).to be_nil
        end
      end

      describe "<attribute>_changed?" do
        it "returns false for an unchanged value" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
        end

        it "new_record returns true" do
          expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq true
        end

        it "new_record returns false if value not set" do
          new_rec = DefaultedTaggerTaggableModel.new

          expect(new_rec.public_send("#{attribute_list}_changed?")).to eq false
        end
      end

      describe "<attribute>_was" do
        it "returns the previous value" do
          taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")

          expect(taggable.public_send("#{attribute_list}_was")).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        end

        it "new_record returns the default" do
          expect(new_taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger]).to eq ["Shazam", "Black Adam"]
        end

        it "new_record returns the default" do
          new_rec = DefaultedTaggerTaggableModel.new

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

      describe "reset_<attribute>_to_default!" do
        it "changes the value to default" do
          taggable.public_send("reset_#{attribute_list}_to_default!")

          expect(taggable.public_send("tagger_#{attribute_list}s")[default_tagger]).to eq ["Shazam", "Black Adam"]
        end

        it "new_record changes the value to default" do
          new_taggable.public_send("reset_#{attribute_list}_to_default!")

          expect(new_taggable.public_send("tagger_#{attribute_list}s")[default_tagger]).to eq ["Shazam", "Black Adam"]
        end
      end
    end

    context "preserve_tag_order" do
      around(:each) do |example_proxy|
        tag_definition            = TaggerTaggableModel.tag_types[tag_name]
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

      describe "<attribute>_change" do
        it "returns change if only order changed" do
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"

          old[unspecified_default_tagger] = %w[Solomon Hercules Atlas Zeus Achilles Mercury]
          new[unspecified_default_tagger] = %w[Solomon Achilles Zeus Atlas Mercury Hercules]

          expect(taggable.public_send("#{attribute_list}_change")).to eq [old, new]
        end

        it "returns nil if changed then changed back" do
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"

          expect(taggable.public_send("#{attribute_list}_change")).to be_nil
        end
      end

      describe "<attribute>_changed?" do
        it "returns true if only order changed" do
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"

          expect(taggable.public_send("#{attribute_list}_changed?")).to eq true
        end

        it "returns false if changed then changed back" do
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Hercules, Atlas, Zeus, Achilles, Mercury"

          expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
        end
      end
    end

    describe "<attribute>?" do
      it "returns true if set" do
        expect(taggable.public_send("#{attribute_list}?")).to eq true
      end

      it "returns false if not set" do
        taggable.public_send("#{attribute_list}=", nil)

        expect(taggable.public_send("#{attribute_list}?")).to eq false
      end
    end

    describe "<attribute>_change" do
      it "returns nil if not changed" do
        expect(taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "returns nil if changed then changed back in different order" do
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"

        expect(taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "returns change array if changed" do
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Shazam"
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Shu, Heru, Amon, Zehuti, Aton, Mehen"

        old[unspecified_default_tagger] = %w[Solomon Hercules Atlas Zeus Achilles Mercury]
        new[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]

        expect(taggable.public_send("#{attribute_list}_change")).to eq [old, new]
      end

      it "new_record returns nil if changed then changed back in different order" do
        new_taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        new_taggable.public_send("#{attribute_list}=", nil)

        expect(new_taggable.public_send("#{attribute_list}_change")).to be_nil
      end

      it "new_record returns change array if changed" do
        old = ActsAsTaggableOnMongoid::TaggerTagList.new(TaggerTaggableModel.tag_types[tag_name], new_taggable)
        new = ActsAsTaggableOnMongoid::TaggerTagList.new(TaggerTaggableModel.tag_types[tag_name], new_taggable)

        old[unspecified_default_tagger] = []
        new[unspecified_default_tagger] = %w[Solomon Hercules Atlas Zeus Achilles Mercury]

        expect(new_taggable.public_send("#{attribute_list}_change")).to eq [old, new]
      end
    end

    describe "<attribute>_changed?" do
      it "returns false if it hasn't changed" do
        expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
      end

      it "new_record returns true if it has changed" do
        expect(new_taggable.public_send("#{attribute_list}_changed?")).to eq true
      end

      it "returns false if changed then changed back in different order" do
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
        taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules"

        expect(taggable.public_send("#{attribute_list}_changed?")).to eq false
      end

      it "new_record returns false if changed then changed back in different order" do
        new_taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = "Shu, Heru, Amon, Zehuti, Aton, Mehen"
        new_taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = nil

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

    describe "<attribute>_will_change!" do
      it "adds <attribute>_will_change!" do
        expect(taggable).to receive(:attribute_will_change!).with attribute_list.to_s

        taggable.public_send("#{attribute_list}_will_change!")
      end
    end

    describe "<attribute>_changed_from_default?" do
      it "is true if it isn't blank" do
        expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to eq true
        expect(new_taggable.public_send("#{attribute_list}_changed_from_default?")).to eq true
      end

      it "returns false if it is blank" do
        taggable.public_send("#{attribute_list}=", nil)

        expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to eq false
      end
    end

    describe "<attribute>_was" do
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

    describe "reset_<attribute>!" do
      it "changes the value back to the initial value" do
        taggable.public_send("#{attribute_list}=", "Shu, Heru, Amon, Zehuti, Aton, Mehen")
        taggable.public_send("#{attribute_list}=", "Solomon, Achilles, Zeus, Atlas, Mercury, Hercules")

        taggable.public_send("reset_#{attribute_list}!")

        expect(taggable.public_send(attribute_list)).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury]
      end

      it "new_record reset_<attribute>! changes the value to default" do
        new_taggable.public_send("reset_#{attribute_list}!")

        expect(new_taggable.public_send(attribute_list)).to be_blank
      end
    end

    describe "reset_<attribute>_to_default!" do
      it "changes the value to []" do
        taggable.public_send("reset_#{attribute_list}_to_default!")

        expect(taggable.public_send(attribute_list)).to be_blank
      end
    end

    describe "<tag_list>?" do
      it "returns false if all lists are blank" do
        taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).clear
        taggable.public_send("tagger_#{attribute_list}", other_user)

        expect(taggable.public_send("tagger_#{attribute_list}s").length).to eq 2
        expect(taggable.public_send("#{attribute_list}?")).to be_falsey
      end

      it "returns true if any list is not blank" do
        taggable.public_send("tagger_#{attribute_list}", other_user)

        expect(taggable.public_send("tagger_#{attribute_list}s").length).to eq 2
        expect(taggable.public_send("#{attribute_list}?")).to be_truthy
      end
    end

    describe "multiple taggers" do
      before(:each) do
        taggable.public_send("tagger_#{attribute_list}s")[other_user] = %w[Shu Heru Amon Zehuti Aton Mehen]
        taggable.save!
        taggable.reload
      end

      describe "change" do
        it "saves multiple taggers properly" do
          expect(taggable.public_send("tagger_#{attribute_list}", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "saves list changes properly" do
          taggable.public_send("tagger_#{attribute_list}", other_user).remove("Heru")
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].remove("Hercules")
          taggable.public_send("tagger_#{attribute_list}", other_user).add("Egypt")
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].add("Greece")

          taggable.save!
          expect(taggable.public_send("tagger_#{attribute_list}", other_user).sort).to eq %w[Shu Amon Zehuti Aton Mehen Egypt].sort
          expect(taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].sort).
              to eq %w[Solomon Atlas Zeus Achilles Mercury Greece].sort

          taggable.reload
          expect(taggable.public_send("tagger_#{attribute_list}", other_user).sort).to eq %w[Shu Amon Zehuti Aton Mehen Egypt].sort
          expect(taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].sort).
              to eq %w[Solomon Atlas Zeus Achilles Mercury Greece].sort
        end

        it "returns if a tag is moved from one owner to another" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 2
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[unspecified_default_tagger].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[other_user].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "is not changed if changed back" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = [%w[Solomon Atlas Zeus Achilles Hercules Mercury],
                                                                                           tagger: unspecified_default_tagger]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Shu Amon Zehuti Aton Heru Mehen]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_change")).to be_blank
        end

        it "returns only the changes if items removed from one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).remove "Hercules"
          taggable.public_send(attribute_list).remove ["Mercury", tagger: unspecified_default_tagger]
          taggable.public_send("tagger_#{attribute_list}s")[other_user] -= "Heru"

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 2
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[unspecified_default_tagger].sort).to eq %w[Solomon Atlas Zeus Achilles].sort
          expect(new[other_user].sort).to eq %w[Shu Amon Zehuti Aton Mehen].sort
        end

        it "returns only the changes if items added to one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).add "Greece"
          taggable.public_send(attribute_list).add "Olympus", tagger: unspecified_default_tagger
          taggable.public_send("tagger_#{attribute_list}s")[other_user] += "Egypt"

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 2
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury Greece Olympus].sort
          expect(new[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen Egypt].sort
        end

        it "returns if one tagger removed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("#{attribute_list}=", nil)
          taggable.public_send("tagger_#{attribute_list}s")[other_user] = [%w[Solomon Atlas Zeus Achilles Hercules Mercury],
                                                                           tagger: unspecified_default_tagger]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 1
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[other_user].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns if one tagger added" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", third_user).add %w[Steve Harvey Alex Zachary Amy Melinda]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 3
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(new[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[third_user].sort).to eq %w[Steve Harvey Alex Zachary Amy Melinda].sort
        end
      end

      describe "<tag_list>_was" do
        it "returns the was value for the default tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "does not affect current value if no changes and changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("#{attribute_list}_was").add "Greece"

          changes = taggable.public_send("tagger_#{attribute_list}s")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect the default if _was is changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("#{attribute_list}_was")
          was.add("Greece")

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "does not affect _was if changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("#{attribute_list}_was")
          was.add("Greece")

          expect(new_taggable.public_send(attribute_list).sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "is not changed if changed back" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          # taggable.public_send("#{attribute_list}=", nil)
          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = [%w[Solomon Atlas Zeus Achilles Hercules Mercury],
                                                                                           tagger: default_tagger]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Shu Amon Zehuti Aton Heru Mehen]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns was if items removed from one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", default_tagger).remove "Hercules"
          taggable.public_send(attribute_list).remove ["Mercury", tagger: default_tagger]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns only the changes if items added to one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", default_tagger).add "Greece"
          taggable.public_send(attribute_list).add "Olympus", tagger: default_tagger

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns if one tagger removed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("#{attribute_list}=", [%w[Solomon Atlas Zeus Achilles Hercules Mercury], tagger: other_user])

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("#{attribute_list}_was").sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns if one tagger added" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", third_user).add %w[Steve Harvey Alex Zachary Amy Melinda]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 2
          expect(new.length).to eq 3
          expect(old[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(old[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(new[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[third_user].sort).to eq %w[Steve Harvey Alex Zachary Amy Melinda].sort
        end
      end

      describe "tagger_<tag_list>_was" do
        it "returns the was value for the default tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect current value if no changes and changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).add "Greece"
          taggable.public_send("tagger_#{attribute_list}_was", other_user).add "Egypt"

          changes = taggable.public_send("tagger_#{attribute_list}s")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect the default if _was is changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger)
          was.add("Greece")
          was = taggable.public_send("tagger_#{attribute_list}_was", other_user)
          was.add("Greece")

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect _was if changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("tagger_#{attribute_list}_was", default_tagger)
          was.add("Greece")
          was = taggable.public_send("tagger_#{attribute_list}_was", other_user)
          was.add("Greece")

          expect(new_taggable.public_send(attribute_list).sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "is not changed if changed back" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          taggable.public_send("#{attribute_list}=", [%w[Solomon Atlas Zeus Achilles Hercules Mercury], tagger: unspecified_default_tagger])
          taggable.public_send("tagger_#{attribute_list}s")[other_user] = %w[Shu Amon Zehuti Aton Heru Mehen]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns was if items removed from one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).remove "Hercules"
          taggable.public_send(attribute_list).remove ["Mercury", tagger: unspecified_default_tagger]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns only the changes if items added to one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).add "Greece"
          taggable.public_send(attribute_list).add "Olympus", tagger: unspecified_default_tagger

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns if one tagger removed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("#{attribute_list}=", [%w[Solomon Atlas Zeus Achilles Hercules Mercury], tagger: other_user])

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns if one tagger added" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", third_user).add %w[Steve Harvey Alex Zachary Amy Melinda]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("tagger_#{attribute_list}_was", third_user).sort).to be_blank
          expect(taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger).sort).
              to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(taggable.public_send("tagger_#{attribute_list}_was", other_user).sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end
      end

      describe "tagger_<tag_list>s_was" do
        it "returns the was value for the default tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect current value if no changes and changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          changes = taggable.public_send("tagger_#{attribute_list}s_was")
          changes[unspecified_default_tagger].add "Greece"
          changes[other_user].add "Egypt"

          changes = taggable.public_send("tagger_#{attribute_list}s")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect the default if _was is changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("tagger_#{attribute_list}_was", unspecified_default_tagger)
          was.add("Greece")
          was = taggable.public_send("tagger_#{attribute_list}_was", other_user)
          was.add("Greece")

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "does not affect _was if changed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          was = taggable.public_send("tagger_#{attribute_list}_was", default_tagger)
          was.add("Greece")
          was = taggable.public_send("tagger_#{attribute_list}_was", other_user)
          was.add("Greece")

          expect(new_taggable.public_send(attribute_list).sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "is not changed if changed back" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}s")[other_user]                 = %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          taggable.public_send("#{attribute_list}=", [%w[Solomon Atlas Zeus Achilles Hercules Mercury], tagger: unspecified_default_tagger])
          taggable.public_send("tagger_#{attribute_list}s")[other_user] = %w[Shu Amon Zehuti Aton Heru Mehen]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns was if items removed from one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).remove "Hercules"
          taggable.public_send(attribute_list).remove ["Mercury", tagger: unspecified_default_tagger]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns only the changes if items added to one tagger" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", unspecified_default_tagger).add "Greece"
          taggable.public_send(attribute_list).add "Olympus", tagger: unspecified_default_tagger

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns if one tagger removed" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("#{attribute_list}=", [%w[Solomon Atlas Zeus Achilles Hercules Mercury], tagger: other_user])

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end

        it "returns if one tagger added" do
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}", third_user).add %w[Steve Harvey Alex Zachary Amy Melinda]

          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          expect(taggable.public_send("tagger_#{attribute_list}_was", third_user).sort).to be_blank
          changes = taggable.public_send("tagger_#{attribute_list}s_was")

          expect(changes.length).to eq 2
          expect(changes[unspecified_default_tagger].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
          expect(changes[other_user].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
        end
      end
    end

    context "with default" do
      let(:taggable) do
        DefaultedTaggerTaggableModel.create! name: "Billy Batson", my_user: my_user
      end
      let(:new_taggable) do
        DefaultedTaggerTaggableModel.new name: "Billy Batson", my_user: my_user
      end

      describe "<tag_list>_changed_from_default?" do
        it "returns true if tags moved to different owner" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_truthy
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy
        end

        it "changes show default in from" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_truthy
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 1
          expect(new.length).to eq 2
          expect(old[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          expect(new[default_tagger].sort).to eq %w[Shu Heru Amon Zehuti Aton Mehen].sort
          expect(new[other_user].sort).to eq %w[Solomon Hercules Atlas Zeus Achilles Mercury].sort
        end

        it "returns false if deleted tag from default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger].remove "Black Adam"

          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_truthy
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 1
          expect(new.length).to eq 1
          expect(old[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          expect(new[default_tagger].sort).to eq ["Shazam"]
        end

        it "returns false if added tag to default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger].add "Merlin"

          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_truthy
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_truthy

          changes = taggable.public_send("#{attribute_list}_change")
          old     = changes[0]
          new     = changes[1]

          expect(old.length).to eq 1
          expect(new.length).to eq 1
          expect(old[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          expect(new[default_tagger].sort).to eq ["Black Adam", "Shazam", "Merlin"].sort
        end
      end

      describe "<tag_list>_was" do
        it "returns default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          if default_tagger == unspecified_default_tagger
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq ["Black Adam", "Shazam"].sort
          else
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq []
            expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          end
        end

        it "returns false if deleted tag from default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].remove "Black Adam"

          if default_tagger == unspecified_default_tagger
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq ["Black Adam", "Shazam"].sort
          else
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq []
            expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          end
        end

        it "returns false if added tag to default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[unspecified_default_tagger].add "Merlin"

          if default_tagger == unspecified_default_tagger
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq ["Black Adam", "Shazam"].sort
          else
            expect(taggable.public_send("#{attribute_list}_was").sort).to eq []
            expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
          end
        end
      end

      describe "tagger_<tag_list>_was" do
        it "returns default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger] = %w[Shu Heru Amon Zehuti Aton Mehen]
          taggable.public_send("tagger_#{attribute_list}", other_user).set %w[Solomon Hercules Atlas Zeus Achilles Mercury]

          expect(taggable.public_send("tagger_#{attribute_list}_was", default_tagger).sort).to eq ["Black Adam", "Shazam"].sort
          expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
        end

        it "returns false if deleted tag from default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger].remove "Black Adam"

          expect(taggable.public_send("tagger_#{attribute_list}_was", default_tagger).sort).to eq ["Black Adam", "Shazam"].sort
          expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
        end

        it "returns false if added tag to default" do
          expect(taggable.public_send("#{attribute_list}_changed_from_default?")).to be_falsey
          expect(taggable.public_send("#{attribute_list}_changed?")).to be_falsey

          taggable.public_send("tagger_#{attribute_list}s")[default_tagger].add "Merlin"

          expect(taggable.public_send("tagger_#{attribute_list}_was", default_tagger).sort).to eq ["Black Adam", "Shazam"].sort
          expect(taggable.public_send("tagger_#{attribute_list}s_was")[default_tagger].sort).to eq ["Black Adam", "Shazam"].sort
        end
      end
    end
  end

  describe "defaulted tags" do
    let(:default_value_tagger) { MyUser.find_or_create_by!(name: "Default Tagger") }
    let(:my_user) { MyUser.create! name: "My User" }

    it "sets the tagger in the default definition" do
      tagged = DefaultedTaggerTaggableModel.new name: "A Taggable", my_user: my_user

      expect(tagged.tagger_default_with_tagger_lists[default_value_tagger]).to eq ["Shazam", "Black Adam"]
      expect(tagged.tagger_default_with_tagger_lists[nil]).to be_blank
      expect(tagged.tagger_default_with_tagger_lists[my_user]).to be_blank
    end

    describe "<tag_list>_was" do
      it "returns change indicators from the default" do
        tagged = DefaultedTaggerTaggableModel.new name: "A Taggable", my_user: my_user

        tagged.tagger_default_with_tagger_lists[default_value_tagger] = ["Billy Batson", "Somebody Else"]

        expect(tagged.tagger_default_with_tagger_list_was(default_value_tagger)).to eq ["Shazam", "Black Adam"]
        expect(tagged.tagger_default_with_tagger_lists_was[default_value_tagger]).to eq ["Shazam", "Black Adam"]
        expect(tagged.default_with_tagger_list_change[0][default_value_tagger]).to eq ["Shazam", "Black Adam"]
        expect(tagged.tagger_default_with_tagger_lists_was[nil]).to be_blank
        expect(tagged.tagger_default_with_tagger_lists_was[my_user]).to be_blank
      end
    end
  end

  context "tag_list" do
    let(:attribute_list) { :tag_list }
    let(:default_tagger) { nil }
    let(:unspecified_default_tagger) { default_tagger }

    it_behaves_like "it adds changeable methods to a taggable object with taggers"
  end

  context "language_list" do
    let(:attribute_list) { :language_list }
    let(:default_tagger) { MyUser.find_or_create_by! name: "Language User" }
    let(:unspecified_default_tagger) { default_tagger }

    it_behaves_like "it adds changeable methods to a taggable object with taggers"
  end

  context "skill_list" do
    let(:attribute_list) { :skill_list }
    let(:default_tagger) { my_user }
    let(:unspecified_default_tagger) { nil }

    it_behaves_like "it adds changeable methods to a taggable object with taggers"
  end

  context "need_list" do
    let(:attribute_list) { :need_list }
    let(:default_tagger) { my_user }
    let(:unspecified_default_tagger) { default_tagger }

    it_behaves_like "it adds changeable methods to a taggable object with taggers"
  end

  context "offering_list" do
    let(:attribute_list) { :offering_list }
    let(:default_tagger) { my_user }
    let(:unspecified_default_tagger) { default_tagger }

    it_behaves_like "it adds changeable methods to a taggable object with taggers"
  end
end
