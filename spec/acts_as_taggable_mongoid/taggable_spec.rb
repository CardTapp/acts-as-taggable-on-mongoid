# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable do
  describe "Taggable To Preserve Order" do
    let(:taggable) { OrderedTaggableModel.new(name: "Bob Jones") }

    it "should have tag associations" do
      %i[tags colours].each do |type|
        expect(taggable.respond_to?(type)).to be_truthy
        expect(taggable.respond_to?("#{type.to_s.singularize}_taggings")).to be_truthy
      end
    end

    it "should have tag methods" do
      %i[tags colours].each do |type|
        expect(taggable.respond_to?("#{type.to_s.singularize}_list")).to be_truthy
        expect(taggable.respond_to?("#{type.to_s.singularize}_list=")).to be_truthy
        expect(taggable.respond_to?("all_#{type}_list")).to be_truthy
      end
    end

    it "should return tag list in the order the tags were created" do
      # create
      taggable.tag_list = "rails, ruby, css"

      expect { taggable.save }.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(3)

      taggable.reload
      expect(taggable.tag_list).to eq(%w[rails ruby css])

      tag_ids = ActsAsTaggableOnMongoid::Models::Tagging.all.to_a.map(&:id).sort

      # update
      taggable.tag_list = "pow, ruby, rails"
      taggable.save

      new_tag_ids = ActsAsTaggableOnMongoid::Models::Tagging.all.to_a.map(&:id).sort
      new_tag_ids.each do |taggable_id|
        expect(tag_ids).not_to be_include(taggable_id)
      end
      tag_ids = new_tag_ids

      taggable.reload
      expect(taggable.tag_list).to eq(%w[pow ruby rails])

      # update with no change
      taggable.tag_list = "pow, ruby, rails"
      taggable.save

      new_tag_ids = ActsAsTaggableOnMongoid::Models::Tagging.all.to_a.map(&:id).sort
      expect(new_tag_ids.sort).to eq tag_ids.sort

      taggable.reload
      expect(taggable.tag_list).to eq(%w[pow ruby rails])

      # update to clear tags
      taggable.tag_list = ""
      taggable.save

      taggable.reload
      expect(taggable.tag_list).to be_empty
    end

    it "should return tag objects in the order the tags were created" do
      # create
      taggable.tag_list = "pow, ruby, rails"

      expect { taggable.save }.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(3)

      taggable.reload
      expect(taggable.tags.map(&:name)).to eq(%w[pow ruby rails])

      # update
      taggable.tag_list = "rails, ruby, css, pow"
      taggable.save

      taggable.reload
      expect(taggable.tag_list).to eq(%w[rails ruby css pow])

      expect(taggable.tags.map(&:name)).to eq(%w[rails ruby css pow])
    end

    xit "should return tag objects in tagging id order" do
      # This test is not supported because we do not have a through query option that we can use to
      # sort this list by.  If a tagging sorted list of tags is ever actually needed, we can look into
      # an option to do this, but at this time, the effort to do it in the code and at run time
      # does not feel worth it, and so I am not doing it.

      # create
      taggable.tag_list = "pow, ruby, rails"
      taggable.save

      taggable.reload
      ids = taggable.tags.map { |t| t.taggings.first.id }
      expect(ids).to eq(ids.sort)

      # update
      taggable.tag_list = "rails, ruby, css, pow"
      taggable.save

      taggable.reload
      ids = taggable.tags.map { |t| t.taggings.first.id }
      expect(ids).to eq(ids.sort)
    end
  end

  describe "Taggable" do
    let(:taggable) { TaggableModel.new(name: "Bob Jones") }
    let(:taggables) { [taggable, TaggableModel.new(name: "John Doe")] }

    it "should have tag types" do
      %i[tags languages skills needs offerings].each do |type|
        expect(TaggableModel.tag_types).to be_key type
      end
    end

    # TODO: Not implemented yet
    xit "should have tag_counts_on" do
      expect(TaggableModel.tag_counts_on(:tags)).to be_empty

      taggable.tag_list = %w[awesome epic]
      taggable.save

      expect(TaggableModel.tag_counts_on(:tags).length).to eq(2)
      expect(taggable.tag_counts_on(:tags).length).to eq(2)
    end

    # TODO: Not implemented yet
    context "tag_counts on a collection" do
      context "a select clause is specified on the collection" do
        xit "should return tag counts without raising an error" do
          expect(TaggableModel.tag_counts_on(:tags)).to be_empty

          taggable.tag_list = %w[awesome epic]
          taggable.save

          expect { expect(TaggableModel.select(:name).tag_counts_on(:tags).length).to eq(2) }.not_to raise_error
        end
      end
    end

    # TODO: Not implemented yet
    xit "should have tags_on" do
      expect(TaggableModel.tags_on(:tags)).to be_empty

      taggable.tag_list = %w[awesome epic]
      taggable.save

      # expect(TaggableModel.tags_on(TaggableModel.tag_types[:tags]).length).to eq(2)
      expect(taggable.tags_on(TaggableModel.tag_types[:tags]).length).to eq(2)
    end

    it "should return [] right after create" do
      blank_taggable = TaggableModel.new(name: "Bob Jones")
      expect(blank_taggable.tag_list).to be_empty
    end

    it "should be able to create tags" do
      taggable.skill_list = "ruby, rails, css"

      expect { taggable.save }.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(3)

      taggable.reload
      expect(taggable.skill_list.sort).to eq(%w[ruby rails css].sort)
    end

    # it "should be able to create tags through the tag list directly" do
    #   taggable.tag_list_on(:test).add("hello")
    #   expect(taggable.tag_list_cache_on(:test)).to_not be_empty
    #   expect(taggable.tag_list_on(:test)).to eq(["hello"])
    #
    #   taggable.save
    #   taggable.save_tags
    #
    #   taggable.reload
    #   expect(taggable.tag_list_on(:test)).to eq(["hello"])
    # end

    it "should differentiate between contexts" do
      taggable.skill_list = "ruby, rails, css"
      taggable.tag_list   = "ruby, bob, charlie"

      taggable.save
      taggable.reload

      expect(taggable.skill_list).to include("ruby")
      expect(taggable.skill_list).to_not include("bob")
    end

    it "should be able to remove tags through list alone" do
      taggable.skill_list = "ruby, rails, css"
      taggable.save
      taggable.reload

      expect(taggable.skills.count).to eq(3)

      taggable.skill_list = "ruby, rails"
      taggable.save
      taggable.reload

      taggable.skills.count
      expect(taggable.skills.count).to eq(2)
    end

    it "should be able to find by tag" do
      taggable.skill_list = "ruby, rails, css"
      taggable.save

      expect(TaggableModel.tagged_with("ruby").first).to eq(taggable)
    end

    # it "should be able to get a count with find by tag when using a group by" do
    #   taggable.skill_list = "ruby"
    #   taggable.save
    #
    #   expect(TaggableModel.tagged_with("ruby", on: :skills).group(:created_at).count.count).to eq(1)
    # end

    it "can be used as scope" do
      TaggableModel.create!(name: "Boby Jones", skill_list: "ruby")

      taggable.skill_list = "ruby"
      taggable.save!

      expect(TaggableModel.tagged_with("ruby").count).to eq 2
      expect(TaggableModel.tagged_with("ruby").where(name: "Bob Jones").count).to eq 1
    end

    it "should be able to find a tag using dates" do
      Timecop.travel(2.days.ago) do
        TaggableModel.create!(name: "Boby Jones", skill_list: "ruby")
      end

      taggable.skill_list = " ruby "
      taggable.save

      today    = Date.today.to_time.utc
      tomorrow = Date.tomorrow.to_time.utc

      expect(TaggableModel.tagged_with(" ruby ", start_at: today, end_at: tomorrow).count).to eq(1)
    end

    it "shouldn't be able to find a tag outside date range" do
      taggable.skill_list = "ruby"
      taggable.save

      expect(TaggableModel.tagged_with("ruby", start_at: Date.today - 2.days, end_at: Date.today - 1.day).count).to eq(0)
    end

    it "should be able to find by tag with context" do
      taggable.skill_list = "ruby, rails, css, julia"
      taggable.tag_list   = "bob, charlie, julia"
      taggable.save

      expect(TaggableModel.tagged_with("ruby").first).to eq(taggable)
      expect(TaggableModel.tagged_with("ruby, css").first).to eq(taggable)
      expect(TaggableModel.tagged_with("bob", on: :skills).first).to_not eq(taggable)
      expect(TaggableModel.tagged_with("bob", on: :tags).first).to eq(taggable)
      expect(TaggableModel.tagged_with("julia", on: :skills).size).to eq(1)
      expect(TaggableModel.tagged_with("julia", on: :tags).size).to eq(1)

      # expect(TaggableModel.tagged_with("julia", on: nil).size).to eq(2)
      expect(TaggableModel.tagged_with("julia", on: nil).size).to eq(1)
    end

    context "should be able to create and find tags in languages without capitalization :" do
      { japanese: { name: "Chihiro", tag_list: "日本の" },
        hebrew:   { name: "Salim", tag_list: "עברית" },
        chinese:  { name: "Ieie", tag_list: "中国的" },
        arabic:   { name: "Yasser", tag_list: "العربية" },
        emo:      { name: "Emo", tag_list: "✏" } }.each do |language, values|
        it language do
          taggable_model = TaggableModel.create(values)
          expect(taggable_model.tag_list).to eq [values[:tag_list]]
        end
      end
    end

    # TODO: Not implemented yet
    xit "should be able to get tag counts on model as a whole" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")
      expect(TaggableModel.tag_counts).to_not be_empty
      expect(TaggableModel.skill_counts).to_not be_empty
    end

    # TODO: Not implemented yet
    xit "should be able to get all tag counts on model as whole" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")

      expect(TaggableModel.all_tag_counts).to_not be_empty
      expect(TaggableModel.all_tag_counts(order: "#{ActsAsTaggableOnMongoid.tags_table}.id").first.count).to eq(3) # ruby
    end

    # TODO: Not implemented yet
    xit "should be able to get all tags on model as whole" do
      pending "I don't know if this test should even work"

      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")

      expect(TaggableModel.all_tags).to_not be_empty
      expect(TaggableModel.all_tags(order: "#{ActsAsTaggableOnMongoid.tags_table}.id").first.name).to eq("ruby")
    end

    it "should be able to use named scopes to chain tag finds by any tags by context" do
      bob = TaggableModel.create(name: "Bob", need_list: "rails", offering_list: "c++")
      TaggableModel.create(name: "Frank", need_list: "css", offering_list: "css")
      TaggableModel.create(name: "Steve", need_list: "c++", offering_list: "java")

      # Let"s only find those who need rails or css and are offering c++ or java
      expect(TaggableModel.tagged_with(["rails, css"], on: :needs, any: true).
          tagged_with(%w[c++ java], on: :offerings, any: true).to_a).to eq([bob])
    end

    it "should not return read-only records" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      expect(TaggableModel.tagged_with("ruby").first).to_not be_readonly
    end

    # TODO: Not implemented yet
    xit "should be able to get scoped tag counts" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")

      expect(TaggableModel.tagged_with("ruby").tag_counts(order: "#{ActsAsTaggableOnMongoid.tags_table}.id").first.count).to eq(2) # ruby
      expect(TaggableModel.tagged_with("ruby").skill_counts.first.count).to eq(1) # ruby
    end

    # TODO: Not implemented yet
    xit "should be able to get all scoped tag counts" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")

      expect(TaggableModel.tagged_with("ruby").all_tag_counts(order: "#{ActsAsTaggableOnMongoid.tags_table}.id").first.count).to eq(3) # ruby
    end

    # TODO: Not implemented yet
    xit "should be able to get all scoped tags" do
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Charlie", skill_list: "ruby")

      expect(TaggableModel.tagged_with("ruby").all_tags(order: "#{ActsAsTaggableOnMongoid.tags_table}.id").first.name).to eq("ruby")
    end

    # TODO: Not implemented yet
    xit "should only return tag counts for the available scope" do
      frank = TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Charlie", skill_list: "ruby, java")

      expect(TaggableModel.tagged_with("rails").all_tag_counts.size).to eq(3)
      expect(TaggableModel.tagged_with("rails").all_tag_counts.any? { |tag| tag.name == "java" }).to be_falsy

      # Test specific join syntaxes:
      frank.untaggable_models.create!
      expect(TaggableModel.tagged_with("rails").joins(:untaggable_models).all_tag_counts.size).to eq(2)
      expect(TaggableModel.tagged_with("rails").joins([:untaggable_models]).all_tag_counts.size).to eq(2)
    end

    # TODO: Not implemented yet
    xit "should only return tags for the available scope" do
      frank = TaggableModel.create(name: "Frank", tag_list: "ruby, rails")
      TaggableModel.create(name: "Bob", tag_list: "ruby, rails, css")
      TaggableModel.create(name: "Charlie", skill_list: "ruby, java")

      expect(TaggableModel.tagged_with("rails").all_tags.count).to eq(3)
      expect(TaggableModel.tagged_with("rails").all_tags.any? { |tag| tag.name == "java" }).to be_falsy

      # Test specific join syntaxes:
      frank.untaggable_models.create!
      expect(TaggableModel.tagged_with("rails").joins(:untaggable_models).all_tags.size).to eq(2)
      expect(TaggableModel.tagged_with("rails").joins([:untaggable_models]).all_tags.size).to eq(2)
    end

    # TODO: Not implemented yet
    xit "should be able to set a custom tag context list" do
      bob = TaggableModel.create(name: "Bob")
      bob.set_tag_list_on(:rotors, "spinning, jumping")
      expect(bob.tag_list_on(:rotors)).to eq(%w[spinning jumping])
      bob.save
      bob.reload
      expect(bob.tags_on(:rotors)).to_not be_empty
    end

    it "should be able to find tagged" do
      bob   = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive", skill_list: "ruby, rails, css")
      frank = TaggableModel.create(name: "Frank", tag_list: "weaker, depressed, inefficient", skill_list: "ruby, rails, css")
      steve = TaggableModel.create(name: "Steve", tag_list: "fitter, happier, more productive", skill_list: "c++, java, ruby")

      expect(TaggableModel.tagged_with("ruby").order_by(:name.asc).to_a).to eq([bob, frank, steve])
      expect(TaggableModel.tagged_with("ruby, rails").order_by(:name.asc).to_a).to eq([bob, frank])
      expect(TaggableModel.tagged_with(%w[ruby rails]).order_by(:name.asc).to_a).to eq([bob, frank])
    end

    it "should be able to find tagged with quotation marks" do
      bob = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive, \"I love the, comma,\"")
      expect(TaggableModel.tagged_with("\"I love the, comma,\"")).to include(bob)
    end

    it "should be able to find tagged with invalid tags" do
      bob = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive")
      expect(TaggableModel.tagged_with("sad, happier")).to_not include(bob)
    end

    it "should be able to find tagged with any tag" do
      bob   = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive", skill_list: "ruby, rails, css")
      frank = TaggableModel.create(name: "Frank", tag_list: "weaker, depressed, inefficient", skill_list: "ruby, rails, css")
      steve = TaggableModel.create(name: "Steve", tag_list: "fitter, happier, more productive", skill_list: "c++, java, ruby")

      expect(TaggableModel.tagged_with(%w[ruby java], any: true).order_by(:name.asc).to_a).to eq([bob, frank, steve])
      expect(TaggableModel.tagged_with(%w[c++ fitter], any: true).order_by(:name.asc).to_a).to eq([bob, steve])
      expect(TaggableModel.tagged_with(%w[depressed css], any: true).order_by(:name.asc).to_a).to eq([bob, frank])
    end

    # TODO: Not implemented yet
    xit "should be able to order by number of matching tags when matching any" do
      bob   = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive", skill_list: "ruby, rails, css")
      frank = TaggableModel.create(name: "Frank", tag_list: "weaker, depressed, inefficient", skill_list: "ruby, rails, css")
      steve = TaggableModel.create(name: "Steve", tag_list: "fitter, happier, more productive", skill_list: "c++, java, ruby")

      expect(TaggableModel.tagged_with(%w[ruby java],
                                       any:                         true,
                                       order_by_matching_tag_count: true,
                                       order:                       "taggable_models.name").to_a).
          to eq([steve, bob, frank])
      expect(TaggableModel.tagged_with(%w[c++ fitter],
                                       any:                         true,
                                       order_by_matching_tag_count: true,
                                       order:                       "taggable_models.name").to_a).
          to eq([steve, bob])
      expect(TaggableModel.tagged_with(%w[depressed css],
                                       any:                         true,
                                       order_by_matching_tag_count: true,
                                       order:                       "taggable_models.name").to_a).
          to eq([frank, bob])
      expect(TaggableModel.tagged_with(%w[fitter happier more productive c++ java ruby],
                                       any:                         true,
                                       order_by_matching_tag_count: true,
                                       order:                       "taggable_models.name").to_a).
          to eq([steve, bob, frank])
      expect(TaggableModel.tagged_with(%w[c++ java ruby fitter], any: true, order_by_matching_tag_count: true, order: "taggable_models.name").to_a).
          to eq([steve, bob, frank])
    end

    context "wild: true" do
      it "should use params as wildcards" do
        bob   = TaggableModel.create(name: "Bob", tag_list: "bob, tricia")
        frank = TaggableModel.create(name: "Frank", tag_list: "bobby, jim")
        steve = TaggableModel.create(name: "Steve", tag_list: "john, patricia")
        jim   = TaggableModel.create(name: "Jim", tag_list: "jim, steve")

        expect(TaggableModel.tagged_with(%w[bob tricia], wild: true, any: true).to_a.sort_by(&:id)).to eq([bob, frank, steve])
        expect(TaggableModel.tagged_with(%w[bob tricia], wild: true, exclude: true).to_a).to eq([jim])
        expect(TaggableModel.tagged_with("ji", wild: true, any: true).to_a =~ [frank, jim])
      end
    end

    # TODO: Not implemented yet
    xit "should be able to find tagged on a custom tag context" do
      bob = TaggableModel.create(name: "Bob")
      bob.set_tag_list_on(:rotors, "spinning, jumping")
      expect(bob.tag_list_on(:rotors)).to eq(%w[spinning jumping])
      bob.save

      expect(TaggableModel.tagged_with("spinning", on: :rotors).to_a).to eq([bob])
    end

    it "should be able to use named scopes to chain tag finds" do
      bob   = TaggableModel.create(name: "Bob", tag_list: "fitter, happier, more productive", skill_list: "ruby, rails, css")
      frank = TaggableModel.create(name: "Frank", tag_list: "weaker, depressed, inefficient", skill_list: "ruby, rails, css")
      steve = TaggableModel.create(name: "Steve", tag_list: "fitter, happier, more productive", skill_list: "c++, java, python")

      # Let"s only find those productive Rails developers
      expect(TaggableModel.tagged_with("rails", on: :skills).order_by(:name.asc).to_a).to eq([bob, frank])
      expect(TaggableModel.tagged_with("happier", on: :tags).order_by(:name.asc).to_a).to eq([bob, steve])
      expect(TaggableModel.tagged_with("rails", on: :skills).tagged_with("happier", on: :tags).to_a).to eq([bob])
      expect(TaggableModel.tagged_with("rails").tagged_with("happier", on: :tags).to_a).to eq([bob])
    end

    it "should be able to find tagged with only the matching tags" do
      TaggableModel.create(name: "Bob", tag_list: "lazy, happier")
      TaggableModel.create(name: "Frank", tag_list: "fitter, happier, inefficient")
      steve = TaggableModel.create(name: "Steve", tag_list: "fitter, happier")

      expect(TaggableModel.tagged_with("fitter, happier", match_all: true).to_a).to eq([steve])
    end

    it "should be able to find tagged with only the matching tags for a context" do
      TaggableModel.create(name: "Bob", tag_list: "lazy, happier", skill_list: "ruby, rails, css")
      frank = TaggableModel.create(name: "Frank", tag_list: "fitter, happier, inefficient", skill_list: "css")
      TaggableModel.create(name: "Steve", tag_list: "fitter, happier", skill_list: "ruby, rails, css")

      expect(TaggableModel.tagged_with("css", on: :skills, match_all: true).to_a).to eq([frank])
    end

    it "should be able to find tagged with some excluded tags" do
      TaggableModel.create(name: "Bob", tag_list: "happier, lazy")
      frank = TaggableModel.create(name: "Frank", tag_list: "happier")
      steve = TaggableModel.create(name: "Steve", tag_list: "happier")

      expect(TaggableModel.tagged_with("lazy", exclude: true)).to include(frank, steve)
      expect(TaggableModel.tagged_with("lazy", exclude: true).size).to eq(2)
    end

    it "should return an empty scope for empty tags" do
      ["", " ", nil, []].each do |tag|
        expect(TaggableModel.tagged_with(tag)).to be_empty
      end
    end

    it "should options key not be deleted" do
      options = { exclude: true }
      TaggableModel.tagged_with("foo", options)
      expect(options).to eq(exclude: true)
    end

    it "should not delete tags if not updated" do
      model = TaggableModel.create(name: "foo", tag_list: "ruby, rails, programming")
      model.update_attributes(name: "bar")
      model.reload
      expect(model.tag_list.sort).to eq(%w[ruby rails programming].sort)
    end

    context "Duplicates" do
      context "should not create duplicate taggings" do
        context "case sensitive" do
          let(:bob) { TaggableModel.create(name: "Bob") }

          it "#add" do
            expect do
              bob.tag_list.add "happier"
              bob.tag_list.add "happier"
              bob.tag_list.add "happier", "rich", "funny"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(3)
          end

          it "#<<" do
            expect do
              bob.tag_list << "social"
              bob.tag_list << "social"
              bob.tag_list << "social" << "wow"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(2)
          end

          it "unicode" do
            expect do
              bob.tag_list.add "ПРИВЕТ"
              bob.tag_list.add "ПРИВЕТ"
              bob.tag_list.add "ПРИВЕТ", "ПРИВЕТ"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
          end

          it "#=" do
            expect do
              bob.tag_list = %w[Happy Happy]
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
          end
        end

        context "case insensitive" do
          let(:bob) { TaggableLowerModel.create(name: "Bob") }

          it "#<<" do
            expect do
              bob.tag_list << "Alone"
              bob.tag_list << "AloNe"
              bob.tag_list << "ALONE" << "In The dark"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(2)
          end

          it "#add" do
            expect do
              bob.tag_list.add "forever"
              bob.tag_list.add "ForEver"
              bob.tag_list.add "FOREVER", "ALONE"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(2)
          end

          it "unicode" do
            expect do
              bob.tag_list.add "ПРИВЕТ"
              bob.tag_list.add "привет", "Привет"
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
          end

          it "#=" do
            expect do
              bob.tag_list = %w[Happy HAPPY]
              bob.save
            end.to change(ActsAsTaggableOnMongoid::Models::Tagging, :count).by(1)
          end
        end
      end

      xit "should not duplicate tags added on different threads", skip: "FIXME, Deadlocks in travis" do
        # TODO: try with more threads and fix deadlock
        thread_count = 4
        barrier      = Barrier.new thread_count

        expect do
          Array.new(thread_count) do
            Thread.start do
              connor          = TaggableModel.first_or_create(name: "Connor")
              connor.tag_list = "There, can, be, only, one"
              barrier.wait
              begin
                connor.save
              rescue ActsAsTaggableOnMongoid::Errors::DuplicateTagError
                # second save should succeed
                connor.save
              end
            end
          end.map(&:join)
        end.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(5)
      end
    end

    describe "Associations" do
      let!(:taggable) { TaggableModel.create!(tag_list: "awesome, epic") }

      it "should not remove tags when creating associated objects" do
        taggable.untaggable_models.create!
        taggable.reload
        expect(taggable.tag_list.size).to eq(2)
      end
    end

    # describe "NonStandardIdTaggable" do
    #   before(:each) do
    #     taggable  = NonStandardIdTaggableModel.new(name: "Bob Jones")
    #     taggables = [taggable, NonStandardIdTaggableModel.new(name: "John Doe")]
    #   end
    #
    #   it "should have tag types" do
    #     %i[tags languages skills needs offerings].each do |type|
    #       expect(NonStandardIdTaggableModel.tag_types).to include type
    #     end
    #
    #     expect(taggable.tag_types).to eq(NonStandardIdTaggableModel.tag_types)
    #   end
    #
    #   it "should have tag_counts_on" do
    #     expect(NonStandardIdTaggableModel.tag_counts_on(:tags)).to be_empty
    #
    #     taggable.tag_list = %w[awesome epic]
    #     taggable.save
    #
    #     expect(NonStandardIdTaggableModel.tag_counts_on(:tags).length).to eq(2)
    #     expect(taggable.tag_counts_on(:tags).length).to eq(2)
    #   end
    #
    #   it "should have tags_on" do
    #     expect(NonStandardIdTaggableModel.tags_on(:tags)).to be_empty
    #
    #     taggable.tag_list = %w[awesome epic]
    #     taggable.save
    #
    #     expect(NonStandardIdTaggableModel.tags_on(:tags).length).to eq(2)
    #     expect(taggable.tags_on(:tags).length).to eq(2)
    #   end
    #
    #   it "should be able to create tags" do
    #     taggable.skill_list = "ruby, rails, css"
    #     expect(taggable.instance_variable_get("@skill_list").instance_of?(ActsAsTaggableOnMongoid::TagList)).to be_truthy
    #
    #     expect { taggable.save }.to change(ActsAsTaggableOnMongoid::Models::Tag, :count).by(3)
    #
    #     taggable.reload
    #     expect(taggable.skill_list.sort).to eq(%w[ruby rails css].sort)
    #   end
    #
    #   it "should be able to create tags through the tag list directly" do
    #     taggable.tag_list_on(:test).add("hello")
    #     expect(taggable.tag_list_cache_on(:test)).to_not be_empty
    #     expect(taggable.tag_list_on(:test)).to eq(["hello"])
    #
    #     taggable.save
    #     taggable.save_tags
    #
    #     taggable.reload
    #     expect(taggable.tag_list_on(:test)).to eq(["hello"])
    #   end
    # end

    # # See https://github.com/mbleigh/acts-as-taggable-on/pull/457 for details
    # context "tag_counts and aggreating scopes, compatability with MySQL " do
    #   before(:each) do
    #     TaggableModel.new(name: "Barb Jones").tap { |t| t.tag_list = %w[awesome fun] }.save
    #     TaggableModel.new(name: "John Doe").tap { |t| t.tag_list = %w[cool fun hella] }.save
    #     TaggableModel.new(name: "Jo Doe").tap { |t| t.tag_list = %w[curious young naive sharp] }.save
    #
    #     TaggableModel.all.each(&:save)
    #   end
    #
    #   context "Model.limit(x).tag_counts.sum(:tags_count)" do
    #     it "should not break on Mysql" do
    #       expect(TaggableModel.limit(2).tag_counts.sum("tags_count").to_i).to eq(5)
    #     end
    #   end
    #
    #   context "regression prevention, just making sure these esoteric queries still work" do
    #     context "Model.tag_counts.limit(x)" do
    #       it "should limit the tag objects (not very useful, of course)" do
    #         array_of_tag_counts = TaggableModel.tag_counts.limit(2)
    #         expect(array_of_tag_counts.count).to eq(2)
    #       end
    #     end
    #
    #     context "Model.tag_counts.sum(:tags_count)" do
    #       it "should limit the total tags used" do
    #         expect(TaggableModel.tag_counts.sum(:tags_count).to_i).to eq(9)
    #       end
    #     end
    #
    #     context "Model.tag_counts.limit(2).sum(:tags_count)" do
    #       it "limit should have no effect; this is just a sanity check" do
    #         expect(TaggableModel.tag_counts.limit(2).sum(:tags_count).to_i).to eq(9)
    #       end
    #     end
    #   end
    # end

    describe "Autogenerated methods" do
      it "should be overridable" do
        expect(TaggableModel.create(tag_list: "woo").tag_list_submethod_called).to be_truthy
      end
    end
  end
end
