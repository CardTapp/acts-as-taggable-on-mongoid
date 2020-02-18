# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition do
  let(:tag_definition) { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(TaggableModel, "tags") }

  %i[parser
     preserve_tag_order
     cached_in_model
     force_lowercase
     force_parameterize
     remove_unused_tags
     tags_table
     taggings_table
     default].each do |param_name|
    it "allows the parameter #{param_name} to be passed in" do
      expect { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(TaggableModel, "tags", param_name => "value") }.not_to raise_error
    end
  end

  it "raises an error if an invalid option is passed in" do
    expect { ActsAsTaggableOnMongoid::Taggable::TagTypeDefinition.new(TaggableModel, "tags", something_invalid: "value") }.
        to raise_error ArgumentError
  end

  describe "parse" do
    it "does not parse a string array and returns at TagList" do
      parsed = tag_definition.parse("this, is, a, list")

      expect(parsed).to be_a ActsAsTaggableOnMongoid::TagList
      expect(parsed).to eq ["this, is, a, list"]
    end

    it "parses a list if told to do so" do
      parsed = tag_definition.parse("this, is, a, list", parse: true)

      expect(parsed).to eq %w[this is a list]
    end

    it "does not parse a list if told not to do so" do
      parsed = tag_definition.parse("this, is, a, list", parse: false)

      expect(parsed).to eq ["this, is, a, list"]
    end

    it "parses using the specified parser" do
      parsed = tag_definition.parse("this, \"is, a\", list", parser: ActsAsTaggableOnMongoid::GenericParser)

      expect(parsed).to eq %w[this "is a" list]
    end

    it "raise an exception with invalid options" do
      expect { tag_definition.parse("this, \"is, a\", list", fail: true) }.to raise_error ArgumentError
    end
  end

  # # <taggings_table>
  # <taggings_table>_ids
  # <taggings_table>_ids=
  # ordered <taggings_table>s
  # <taggings_table>s=
  # <taggings_table>s?
  # has_<taggings_table>s?
  #
  # # <tag_table>
  # base_<tag_table>
  #
  # # alt_tagging_other_tags
  # <tag_field>s
  # ordered <tag_field>_list
  # <tag_field>_list=
  # <tag_field>_list_before_type_cast
  # all_<tag_field>s_list

  # ordered <tag_field>_<taggings_table>

  describe "added methods" do
    # # ordered <tag_field>_<taggings_table>
    RSpec.shared_examples "adds related ordered Taggings methods" do |tag_list_name, other_tag_list_name, taggings_table, taggings_tables|
      context tag_list_name do
        let!(:tagged) do
          tagged_class.create! name:               "Virgil Hawkins",
                               tag_list_name       => "Ebon, Botanist, Coil, Crime Alliance, Dark Side Club",
                               other_tag_list_name => "John Tower, LaserJet"
        end
        let!(:other_tagged) do
          tagged_class.create! name:               "Virgil Hawkins",
                               tag_list_name       => "Ebon, Dr. Byron Kilgore, Don Cornelius, Blinder, Howell Rice/Commando X",
                               other_tag_list_name => "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak"
        end
        let!(:tag_ordered_tagings) do
          ordered_tagings.select { |tagging| ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].include? tagging.tag_name }
        end
        let!(:ordered_tagings) do
          taggings = tagged.send(taggings_tables).all.to_a.sample(100)

          index = -1
          taggings.each do |tagging|
            index += 1

            tagging.created_at = (100 - index).hours.ago
            tagging.save!
          end

          taggings
        end

        it_behaves_like "adds related Taggings methods", tag_list_name, other_tag_list_name, taggings_table, taggings_tables

        context "#{tag_list_name[0..-6]}_#{taggings_tables}" do
          it "returns taggable objects for the tag in order" do
            ordered_list = "#{tag_list_name[0..-6]}_#{taggings_tables}"

            expect(tagged.send(ordered_list)).to eq tag_ordered_tagings
            expect(tagged.send(ordered_list).map(&:tag_name).sort).to eq tag_ordered_tagings.map(&:tag_name).sort
            expect(tagged.send(ordered_list).map(&:tag_name).sort).
                to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].sort
          end
        end
      end
    end

    # - <taggings_table>
    # # <taggings_table>s
    # # <taggings_table>_ids
    # # <taggings_table>_ids=
    # # <taggings_table>s=
    # # <taggings_table>s?
    # # has_<taggings_table>s?
    # # <tag_field>_<taggings_table>
    RSpec.shared_examples "adds related Taggings methods" do |tag_list_name, other_tag_list_name, taggings_table, taggings_tables|
      context tag_list_name do
        let!(:tagged) do
          tagged_class.create! name:               "Virgil Hawkins",
                               tag_list_name       => "Ebon, Botanist, Coil, Crime Alliance, Dark Side Club",
                               other_tag_list_name => "John Tower, LaserJet"
        end
        let!(:other_tagged) do
          tagged_class.create! name:               "Virgil Hawkins",
                               tag_list_name       => "Ebon, Dr. Byron Kilgore, Don Cornelius, Blinder, Howell Rice/Commando X",
                               other_tag_list_name => "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak"
        end
        let!(:tag_ordered_tagings) do
          ordered_tagings.select { |tagging| ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].include? tagging.tag_name }
        end
        let!(:ordered_tagings) do
          taggings = tagged.send(taggings_tables).all.to_a.sample(100)

          index = -1
          taggings.each do |tagging|
            index += 1

            tagging.created_at = (100 - index).hours.ago
            tagging.save!
          end

          taggings
        end

        context taggings_tables do
          it "returns owned records" do
            expect(tagged.send(taggings_tables)).not_to eq ordered_tagings
            expect(tagged.send(taggings_tables).map(&:tag_name).sort).to eq ordered_tagings.map(&:tag_name).sort
            expect(tagged.send(taggings_tables).map(&:tag_name).sort).
                to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club", "John Tower", "LaserJet"].sort
          end

          it "returns owned ids" do
            expect(tagged.send("#{taggings_table}_ids").sort).to eq ordered_tagings.map(&:id).sort
            expect(tagged.send(taggings_tables).map(&:tag_name).sort).to eq ordered_tagings.map(&:tag_name).sort
            expect(ordered_tagings.map(&:tag_name).sort).
                to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club", "John Tower", "LaserJet"].sort
          end

          it "responds to #{taggings_tables}=" do
            expect(tagged).to be_respond_to("#{taggings_tables}=")
          end

          it "responds to #{taggings_table}_ids=" do
            expect(tagged).to be_respond_to("#{taggings_table}_ids=")
          end
        end

        it "destroys records when the object is destroyed" do
          klass = tagged.send(taggings_tables).first.class

          expect { tagged.reload.destroy }.to change { klass.count }.by(-7)
        end

        context "#{tag_list_name[0..-6]}_#{taggings_tables}" do
          it "returns taggable objects for the tag" do
            ordered_list = "#{tag_list_name[0..-6]}_#{taggings_tables}"

            expect(tagged.send(ordered_list).map(&:tag_name).sort).to eq tag_ordered_tagings.map(&:tag_name).sort
            expect(tagged.send(ordered_list).map(&:tag_name).sort).
                to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].sort
          end
        end

        context "taggings exists" do
          context "no taggings" do
            before(:each) do
              klass = tagged.send(taggings_tables).first.class

              klass.destroy_all
            end

            it "#{taggings_tables}? is false" do
              expect(tagged.reload.send("#{taggings_tables}?")).to be_falsey
            end

            it "has_#{taggings_tables}? is false" do
              expect(tagged.reload.send("has_#{taggings_tables}?")).to be_falsey
            end
          end

          it "#{taggings_tables}? is true" do
            expect(tagged.reload.send("#{taggings_tables}?")).to be_truthy
          end

          it "has_#{taggings_tables}? is true" do
            expect(tagged.reload.send("has_#{taggings_tables}?")).to be_truthy
          end
        end
      end
    end

    # # <tag_table>
    # base_<tag_table>
    RSpec.shared_examples "adds related Tags methods" do |tag_list_name, other_tag_list_name, tags_table|
      let!(:tagged) do
        tagged_class.create! name:         "Virgil Hawkins",
                             tag_list_name => "Ebon, Botanist, Coil, Crime Alliance, Dark Side Club"
      end
      let!(:other_tagged) do
        tagged_class.create! name:         "Virgil Hawkins",
                             tag_list_name => "Ebon, Dr. Byron Kilgore, Don Cornelius, Blinder, Howell Rice/Commando X"
      end
      let!(:alt_tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             other_tag_list_name => "John Tower, LaserJet"
      end
      let!(:alt_other_tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             other_tag_list_name => "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak"
      end

      context tag_list_name do
        context "base_#{tags_table}" do
          it "returns all of the tags for the taggable model" do
            expect(tagged.send("base_#{tags_table}").map(&:name).sort).
                to eq ["Ebon",
                       "Botanist",
                       "Coil",
                       "Crime Alliance",
                       "Dark Side Club",
                       "Dr. Byron Kilgore",
                       "Don Cornelius", "Blinder",
                       "Howell Rice/Commando X",
                       "John Tower",
                       "Leonard Smalls/Pyre/Holocaust",
                       "Martin Scaponi/Hotstreak",
                       "LaserJet"].sort
          end
        end
      end
    end

    RSpec.shared_examples "adds defaults" do |tag_list_name, tag_field_name, tag_class|
      context "#{tag_list_name} default value" do
        around(:each) do |example_proxy|
          tag_definition = tag_class.tag_types[tag_field_name]
          orig_default   = tag_definition&.instance_variable_get(:@default)

          begin
            tag_definition&.send(:default_value=, ["defaulted, tag, \"lists, are\", fun", parser: ActsAsTaggableOnMongoid::GenericParser])

            example_proxy.run
          ensure
            tag_definition&.instance_variable_set(:@default, orig_default)
          end
        end

        it "sets defaults for the tagging_list when created without one" do
          tagged = tagged_class.new(name: "Simple Name")

          expect(tagged.send(tag_list_name).sort).to eq ["defaulted", "tag", "\"lists", "are\"", "fun"].sort
        end

        it "ignores defaults if created with a list" do
          tagged = tagged_class.new(name: "Simple Name", tag_list_name => "something, \"to, do\"")

          expect(tagged.send(tag_list_name).sort).to eq ["something", "to, do"].sort
        end

        it "overrides defaults with nil if created with a list" do
          tagged = tagged_class.new(name: "Simple Name", tag_list_name => nil)

          expect(tagged.send(tag_list_name).sort).to be_blank
        end
      end
    end

    RSpec.shared_examples "adds ordered tag list methods" do |tag_list_name, other_tag_list_name, tag_field_name, taggings_tables|
      let!(:tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             tag_list_name       => "Ebon, Botanist, Coil, Crime Alliance, Dark Side Club",
                             other_tag_list_name => "John Tower, LaserJet"
      end
      let!(:other_tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             tag_list_name       => "Ebon, Dr. Byron Kilgore, Don Cornelius, Blinder, Howell Rice/Commando X",
                             other_tag_list_name => "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak"
      end
      let!(:tag_ordered_tagings) do
        ordered_tagings.select { |tagging| ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].include? tagging.tag_name }
      end
      let!(:ordered_tagings) do
        taggings = tagged.send(taggings_tables).all.to_a.sample(100)

        index = -1
        taggings.each do |tagging|
          index += 1

          tagging.created_at = (100 - index).hours.ago
          tagging.save!
        end

        taggings
      end

      it_behaves_like "adds tag list methods", tag_list_name, other_tag_list_name, tag_field_name

      context tag_field_name do
        it "returns a list tags for this taggable" do
          expect(tagged.send(tag_field_name).to_a).to eq tag_ordered_tagings.map(&:tag)
        end
      end

      context "#{tag_list_name}_before_type_cast" do
        it "return an ordered list of tag names" do
          expect(tagged.reload.send("#{tag_list_name}_before_type_cast")).to eq tag_ordered_tagings.map(&:tag_name)
        end
      end

      context tag_list_name do
        it "return an ordered list of tag names" do
          expect(tagged.reload.send(tag_list_name)).to eq tag_ordered_tagings.map(&:tag_name)
        end

        it "sets tag names in an ordered manner" do
          new_tags = tagged.reload.send(tag_list_name)

          new_tags = new_tags[0..-4].to_a + [new_tags[-1], new_tags[-2], "Nathan Flack/Dr. Nemo", new_tags[-3]]

          tagged.send("#{tag_list_name}=", new_tags)
          tagged.save!

          expect(tagged.reload.send(tag_list_name)).to eq new_tags
        end
      end
    end

    # # alt_tagging_other_tags
    # <tag_field>s
    # ordered <tag_field>_list
    # <tag_field>_list=
    # <tag_field>_list_before_type_cast
    # all_<tag_field>s_list
    RSpec.shared_examples "adds tag list methods" do |tag_list_name, other_tag_list_name, tag_field_name|
      let!(:tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             tag_list_name       => "Ebon, Botanist, Coil, Crime Alliance, Dark Side Club",
                             other_tag_list_name => "John Tower, LaserJet"
      end
      let!(:other_tagged) do
        tagged_class.create! name:               "Virgil Hawkins",
                             tag_list_name       => "Ebon, Dr. Byron Kilgore, Don Cornelius, Blinder, Howell Rice/Commando X",
                             other_tag_list_name => "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak"
      end

      context "all_#{tag_field_name}_list" do
        it "returns a list of all tags for the tag_definition" do
          expect(tagged.send("all_#{tag_field_name}_list").sort).
              to eq ["Ebon",
                     "Botanist",
                     "Coil",
                     "Crime Alliance",
                     "Dark Side Club"].sort
        end
      end

      context tag_field_name do
        it "returns a list tags for this taggable" do
          expect(tagged.send(tag_field_name).map(&:name).sort).
              to eq ["Ebon",
                     "Botanist",
                     "Coil",
                     "Crime Alliance",
                     "Dark Side Club"].sort
        end
      end

      context "#{tag_list_name}_before_type_cast" do
        it "return a list of tag names" do
          expect(tagged.send("#{tag_list_name}_before_type_cast").sort).to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].sort
        end
      end

      context "#{tag_list_name}=" do
        it "sets the list of tag" do
          tagged.send("#{tag_list_name}=", "John Tower, Leonard Smalls/Pyre/Holocaust, Martin Scaponi/Hotstreak")
          expect(tagged.send(tag_list_name).sort).to eq ["John Tower", "Leonard Smalls/Pyre/Holocaust", "Martin Scaponi/Hotstreak"].sort
        end
      end

      context tag_list_name do
        it "return a list of tag names" do
          expect(tagged.send(tag_list_name).sort).to eq ["Ebon", "Botanist", "Coil", "Crime Alliance", "Dark Side Club"].sort
        end
      end
    end

    context TaggableModel do
      let(:tagged_class) { TaggableModel }

      it_behaves_like "adds tag list methods", :tag_list, :language_list, :tags
      it_behaves_like "adds tag list methods", :language_list, :tag_list, :languages
      it_behaves_like "adds tag list methods", :skill_list, :tag_list, :skills
      it_behaves_like "adds tag list methods", :need_list, :tag_list, :needs
      it_behaves_like "adds tag list methods", :offering_list, :tag_list, :offerings

      it_behaves_like "adds defaults", :tag_list, :tags, TaggableModel
      it_behaves_like "adds defaults", :language_list, :languages, TaggableModel
      it_behaves_like "adds defaults", :skill_list, :skills, TaggableModel
      it_behaves_like "adds defaults", :need_list, :needs, TaggableModel
      it_behaves_like "adds defaults", :offering_list, :offerings, TaggableModel

      it_behaves_like "adds related Taggings methods", :tag_list, :language_list, :tagging, :taggings
      it_behaves_like "adds related Taggings methods", :language_list, :tag_list, :tagging, :taggings
      it_behaves_like "adds related Taggings methods", :skill_list, :tag_list, :tagging, :taggings
      it_behaves_like "adds related Taggings methods", :need_list, :tag_list, :tagging, :taggings
      it_behaves_like "adds related Taggings methods", :offering_list, :tag_list, :tagging, :taggings

      it_behaves_like "adds related Tags methods", :language_list, :tag_list, :tags
    end

    context OrderedTaggableModel do
      let(:tagged_class) { OrderedTaggableModel }

      it_behaves_like "adds ordered tag list methods", :tag_list, :colour_list, :tags, :taggings
      it_behaves_like "adds ordered tag list methods", :colour_list, :tag_list, :colours, :taggings

      it_behaves_like "adds defaults", :tag_list, :tags, OrderedTaggableModel
      it_behaves_like "adds defaults", :colour_list, :colours, OrderedTaggableModel

      it_behaves_like "adds related ordered Taggings methods", :tag_list, :colour_list, :tagging, :taggings
      it_behaves_like "adds related ordered Taggings methods", :colour_list, :tag_list, :tagging, :taggings

      it_behaves_like "adds related Tags methods", :colour_list, :tag_list, :tags
    end

    context AltTagged do
      let(:tagged_class) { AltTagged }

      it_behaves_like "adds tag list methods", :tag_list, :alt_tagging_other_tag_list, :tags
      it_behaves_like "adds tag list methods", :alt_tagging_other_tag_list, :tag_list, :alt_tagging_other_tags
      it_behaves_like "adds tag list methods", :other_tagging_alt_tag_list, :other_tagging_other_tag_list, :other_tagging_alt_tags

      it_behaves_like "adds ordered tag list methods",
                      :other_tagging_other_tag_list,
                      :more_other_tagging_other_tag_list,
                      :other_tagging_other_tags,
                      :other_taggings
      it_behaves_like "adds ordered tag list methods",
                      :more_other_tagging_other_tag_list,
                      :other_tagging_other_tag_list,
                      :more_other_tagging_other_tags, :other_taggings
      it_behaves_like "adds ordered tag list methods",
                      :another_other_tagging_other_tag_list,
                      :other_tagging_other_tag_list,
                      :another_other_tagging_other_tags,
                      :other_taggings

      it_behaves_like "adds defaults", :tag_list, :tags, AltTagged
      it_behaves_like "adds defaults", :alt_tagging_other_tag_list, :alt_tagging_other_tags, AltTagged
      it_behaves_like "adds defaults", :other_tagging_alt_tag_list, :other_tagging_alt_tags, AltTagged
      it_behaves_like "adds defaults", :other_tagging_other_tag_list, :other_tagging_other_tags, AltTagged
      it_behaves_like "adds defaults", :more_other_tagging_other_tag_list, :more_other_tagging_other_tags, AltTagged
      it_behaves_like "adds defaults", :another_other_tagging_other_tag_list, :another_other_tagging_other_tags, AltTagged

      it_behaves_like "adds related Taggings methods",
                      :tag_list,
                      :alt_tagging_other_tag_list,
                      :alt_tagging,
                      :alt_taggings
      it_behaves_like "adds related Taggings methods",
                      :alt_tagging_other_tag_list,
                      :tag_list,
                      :alt_tagging,
                      :alt_taggings
      it_behaves_like "adds related Taggings methods",
                      :other_tagging_alt_tag_list,
                      :other_tagging_other_tag_list,
                      :other_tagging,
                      :other_taggings

      it_behaves_like "adds related ordered Taggings methods",
                      :other_tagging_other_tag_list,
                      :more_other_tagging_other_tag_list,
                      :other_tagging,
                      :other_taggings
      it_behaves_like "adds related ordered Taggings methods",
                      :more_other_tagging_other_tag_list,
                      :other_tagging_other_tag_list,
                      :other_tagging,
                      :other_taggings
      it_behaves_like "adds related ordered Taggings methods",
                      :another_other_tagging_other_tag_list,
                      :other_tagging_other_tag_list,
                      :other_tagging,
                      :other_taggings

      it_behaves_like "adds related Tags methods", :tag_list, :tag_list, :alt_tags
      it_behaves_like "adds related Tags methods", :alt_tagging_other_tag_list, :alt_tagging_other_tag_list, :other_alt_tags
      it_behaves_like "adds related Tags methods", :other_tagging_alt_tag_list, :other_tagging_alt_tag_list, :other_tags
      it_behaves_like "adds related Tags methods", :other_tagging_other_tag_list, :more_other_tagging_other_tag_list, :other_other_tags
      it_behaves_like "adds related Tags methods", :more_other_tagging_other_tag_list, :other_tagging_other_tag_list, :other_other_tags
      it_behaves_like "adds related Tags methods", :another_other_tagging_other_tag_list, :other_tagging_other_tag_list, :other_other_tags
    end
  end
end
