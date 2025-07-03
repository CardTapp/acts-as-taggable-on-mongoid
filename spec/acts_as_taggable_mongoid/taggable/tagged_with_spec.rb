# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Taggable::TaggedWith do
  # let!(:a) { TaggableModel.create!(name: "a", tag_list: "a, b, c, d, \"a, d\"", language_list: "d, e, f", skill_list: "a, d, g, h") }
  # let!(:b) { TaggableModel.create!(name: "b", tag_list: "b, d", language_list: "a, e, \"a, d\"", skill_list: "a, d, i") }
  # let!(:no_parse) { TaggableModel.create!(name: "no_parse", tag_list: ["y, z, \"a, d\"", parser: ActsAsTaggableOnMongoid::GenericParser]) }
  # let!(:a_o) { OrderedTaggableModel.create!(name: "a_o", tag_list: "a, b, c, d", colour_list: "d, e, f") }

  describe "tagged_with" do
    describe ":on" do
      context "single context" do
        let!(:taggable_one) { TaggableModel.create!(name: "a", skill_list: "a, d, g, i, k") }
        let!(:taggable_two) { TaggableModel.create!(name: "a", skill_list: "a, d, h") }
        let!(:taggable_three) { TaggableModel.create!(name: "a", skill_list: "a, i") }
        let!(:taggable_four) { TaggableModel.create!(name: "a", skill_list: "g, j") }
        let!(:taggable_five) { TaggableModel.create!(name: "a", skill_list: "g, k") }

        before(:each) do
          TaggableModel.create!(name: "a", language_list: "a, d, g, h, i, j")
          TaggableModel.create!(name: "a", language_list: "g, h, j")
          InheritingTaggableModel.create!(name: "a", skill_list: "a, d, g, i, k")
          InheritingTaggableModel.create!(name: "a", skill_list: "a, d, h")
          InheritingTaggableModel.create!(name: "a", skill_list: "a, i")
          InheritingTaggableModel.create!(name: "a", skill_list: "g, j")
          InheritingTaggableModel.create!(name: "a", skill_list: "g, k")
        end

        it "all" do
          expect(TaggableModel.tagged_with("a, g", context: :skills, all: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("a, g, z", context: :skills, all: true).map(&:id).sort).to be_blank
        end

        it "match_all" do
          expect(TaggableModel.tagged_with("a, d, h", context: :skills, match_all: true).map(&:id).sort).to eq [taggable_two.id].sort
          expect(TaggableModel.tagged_with("a, d, h, i", context: :skills, match_all: true).map(&:id).sort).to be_blank
        end

        it "any" do
          expect(TaggableModel.tagged_with("a, g", context: :skills, any: true).map(&:id).sort).
              to eq [taggable_one.id, taggable_two.id, taggable_three.id, taggable_four.id, taggable_five.id].sort
          expect(TaggableModel.tagged_with("aa, gg", context: :skills, any: true).map(&:id).sort).to be_blank
        end

        it "exclude" do
          expect(TaggableModel.tagged_with("a, k", context: :skills, exclude: true).map(&:id).sort).to eq [taggable_four.id].sort
          expect(TaggableModel.tagged_with("a, g", context: :skills, exclude: true).map(&:id).sort).to be_blank
        end
      end

      context "a set of contexts" do
        let!(:taggable_one) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "a",
                                skill_list:    "a, b",
                                language_list: "c, d",
                                need_list:     "d, e",
                                offering_list: "e, f")
        end
        let!(:taggable_two) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "f",
                                skill_list:    "e, b",
                                language_list: "d, c",
                                need_list:     "c, a",
                                offering_list: "b, a")
        end

        before(:each) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "a, b, c, d, e, f",
                                skill_list:    "x, y",
                                language_list: "z, v",
                                need_list:     "u, w",
                                offering_list: "b, d, e, t, s")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "a",
                                          skill_list:    "a, b",
                                          language_list: "c, d",
                                          need_list:     "d, e",
                                          offering_list: "e, f")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "f",
                                          skill_list:    "e, b",
                                          language_list: "d, c",
                                          need_list:     "c, a",
                                          offering_list: "b, a")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "a, b, c, d, e, f",
                                          skill_list:    "x, y",
                                          language_list: "z, v",
                                          need_list:     "u, w",
                                          offering_list: "b, d, e, t, s")
        end

        it "all" do
          expect(TaggableModel.tagged_with("a, d", context: %i[skills languages], all: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("a, d, z", context: %i[skills languages], all: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("a, e", context: %i[skills needs], all: true).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
        end

        it "match_all" do
          expect(TaggableModel.tagged_with("a, b, c, d", context: %i[skills languages], match_all: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("a, b, d", context: %i[skills languages], match_all: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("a, b, c, d, e", context: %i[skills languages], match_all: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("a, b, c, d, e", context: %i[skills languages needs], match_all: true).map(&:id).sort).
              to eq [taggable_one.id, taggable_two.id].sort
        end

        it "any" do
          expect(TaggableModel.tagged_with("a, f", context: %i[skills languages], any: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("aa, bb", context: %i[skills languages], any: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("a, e", context: %i[skills needs], any: true).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
        end

        it "exclude" do
          expect(TaggableModel.tagged_with("b, c", context: %i[needs offerings], exclude: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("d, f", context: %i[skills offerings], exclude: true).map(&:id).sort).to eq [taggable_two.id].sort
        end
      end

      context "all contexts" do
        let!(:taggable_one) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "a, b",
                                skill_list:    "c, d",
                                language_list: "e, f",
                                need_list:     "g, h",
                                offering_list: "i, j")
        end
        let!(:taggable_two) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "k, l",
                                skill_list:    "m, n",
                                language_list: "o, p",
                                need_list:     "q, r",
                                offering_list: "s, t")
        end

        before(:each) do
          TaggableModel.create!(name:          "a",
                                tag_list:      "aa, bb",
                                skill_list:    "cc, dd",
                                language_list: "ee, ff",
                                need_list:     "gg, hh",
                                offering_list: "ii, jj")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "a, b",
                                          skill_list:    "c, d",
                                          language_list: "e, f",
                                          need_list:     "g, h",
                                          offering_list: "i, j")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "k, l",
                                          skill_list:    "m, n",
                                          language_list: "o, p",
                                          need_list:     "q, r",
                                          offering_list: "s, t")
          InheritingTaggableModel.create!(name:          "a",
                                          tag_list:      "aa, bb",
                                          skill_list:    "cc, dd",
                                          language_list: "ee, ff",
                                          need_list:     "gg, hh",
                                          offering_list: "ii, jj")
        end

        it "all" do
          expect(TaggableModel.tagged_with("a, j", context: nil, all: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("k, l", context: nil, all: true).map(&:id).sort).to eq [taggable_two.id].sort
        end

        it "match_all" do
          expect(TaggableModel.tagged_with("a, b, c, d, e, f, g, h, i, j", context: nil, match_all: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("a, b, c, d, f, g, h, i, j", context: nil, match_all: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("a, b, c, d, e, f, g, h, i, j, k", context: nil, match_all: true).map(&:id).sort).to be_blank
          expect(TaggableModel.tagged_with("k, l, m, n, o, p, q, r, s, t", context: nil, match_all: true).map(&:id).sort).to eq [taggable_two.id].sort
        end

        it "any" do
          expect(TaggableModel.tagged_with("a, f", context: nil, any: true).map(&:id).sort).to eq [taggable_one.id].sort
          expect(TaggableModel.tagged_with("k, t", context: nil, any: true).map(&:id).sort).to eq [taggable_two.id].sort
          expect(TaggableModel.tagged_with("zz, qq", context: nil, any: true).map(&:id).sort).to be_blank
        end

        it "exclude" do
          ids = TaggableModel.tagged_with("a, j", context: nil, exclude: true).map(&:id)
          expect(ids.length).to eq 2
          expect(ids).not_to be_include taggable_one.id

          ids = TaggableModel.tagged_with("k, t", context: nil, exclude: true).map(&:id)
          expect(ids.length).to eq 2
          expect(ids).not_to be_include taggable_two.id
        end
      end
    end

    describe ":start_at" do
      let!(:taggable_one) do
        Timecop.travel(2.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end
      let!(:taggable_two) do
        Timecop.travel(4.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end

      before(:each) do
        Timecop.travel(6.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end

      it "all" do
        expect(TaggableModel.tagged_with("a, d, z", all: true, start_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, d", all: true, start_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, d", all: true, start_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, d", all: true, start_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end

      it "match_all" do
        expect(TaggableModel.tagged_with("a, d, z", match_all: true, start_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, start_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, start_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, start_at: 5.days.ago).map(&:id).sort).
            to eq [taggable_one.id, taggable_two.id].sort
      end

      it "any" do
        expect(TaggableModel.tagged_with("y, z", any: true, start_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, z", any: true, start_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, z", any: true, start_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, z", any: true, start_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end

      it "exclude" do
        expect(TaggableModel.tagged_with("a, b", exclude: true, start_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("y, z", exclude: true, start_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("y, z", exclude: true, start_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("y, z", exclude: true, start_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end
    end

    describe ":end_at" do
      let!(:taggable_one) do
        Timecop.travel(6.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end
      let!(:taggable_two) do
        Timecop.travel(4.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end

      before(:each) do
        Timecop.travel(2.days.ago) do
          InheritingTaggableModel.create! name: "a", tag_list: "a, b, c, d"
          TaggableModel.create! name: "a", tag_list: "a, b, c, d"
        end
      end

      it "all" do
        expect(TaggableModel.tagged_with("a, d, z", all: true, end_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, d", all: true, end_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, d", all: true, end_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, d", all: true, end_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end

      it "match_all" do
        expect(TaggableModel.tagged_with("a, d, z", match_all: true, end_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, end_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, end_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, b, c, d", match_all: true, end_at: 3.days.ago).map(&:id).sort).
            to eq [taggable_one.id, taggable_two.id].sort
      end

      it "any" do
        expect(TaggableModel.tagged_with("y, z", any: true, end_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, z", any: true, end_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, z", any: true, end_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, z", any: true, end_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end

      it "exclude" do
        expect(TaggableModel.tagged_with("a, b", exclude: true, end_at: 1.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("y, z", exclude: true, end_at: 7.days.ago).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("y, z", exclude: true, end_at: 5.days.ago).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("y, z", exclude: true, end_at: 3.days.ago).map(&:id).sort).to eq [taggable_one.id, taggable_two.id].sort
      end
    end

    describe ":wild" do
      let!(:taggable_one) do
        TaggableModel.create!(name:          "aa",
                              tag_list:      "aa",
                              skill_list:    "aa, bb",
                              language_list: "cc, dd",
                              need_list:     "dd, ee",
                              offering_list: "ee, ff")
      end
      let!(:taggable_two) do
        TaggableModel.create!(name:          "a",
                              tag_list:      "ff",
                              skill_list:    "ee, bb",
                              language_list: "dd, cc",
                              need_list:     "cc, aa",
                              offering_list: "bb, aa")
      end

      before(:each) do
        TaggableModel.create!(name:          "a",
                              tag_list:      "aa, bb, cc, dd, ee, ff",
                              skill_list:    "xx, yy",
                              language_list: "zz, vv",
                              need_list:     "uu, ww",
                              offering_list: "bb, dd, ee, tt, ss")
        InheritingTaggableModel.create!(name:          "a",
                                        tag_list:      "aa",
                                        skill_list:    "aa, bb",
                                        language_list: "cc, dd",
                                        need_list:     "dd, ee",
                                        offering_list: "ee, ff")
        InheritingTaggableModel.create!(name:          "a",
                                        tag_list:      "d",
                                        skill_list:    "ee, bb",
                                        language_list: "dd, cc",
                                        need_list:     "cc, aa",
                                        offering_list: "bb, aa")
        InheritingTaggableModel.create!(name:          "a",
                                        tag_list:      "aa, bb, cc, dd, ee, ff",
                                        skill_list:    "xx, yy",
                                        language_list: "zz, vv",
                                        need_list:     "uu, ww",
                                        offering_list: "bb, dd, ee, tt, ss")
      end

      it "all" do
        expect(TaggableModel.tagged_with("a, d", context: %i[skills languages], wild: true, all: true).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, d, z", context: %i[skills languages], wild: true, all: true).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, e", context: %i[skills needs], wild: true, all: true).map(&:id).sort).
            to eq [taggable_one.id, taggable_two.id].sort
      end

      it "match_all" do
        expect(TaggableModel.tagged_with("a, b, c, d", context: %i[skills languages], wild: true, match_all: true).map(&:id).sort).
            to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("a, b, d", context: %i[skills languages], wild: true, match_all: true).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d, e", context: %i[skills languages], wild: true, match_all: true).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, b, c, d, e", context: %i[skills languages needs], wild: true, match_all: true).map(&:id).sort).
            to eq [taggable_one.id, taggable_two.id].sort
      end

      it "any" do
        expect(TaggableModel.tagged_with("a, f", context: %i[skills languages], wild: true, any: true).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("ab, ba", context: %i[skills languages], wild: true, any: true).map(&:id).sort).to be_blank
        expect(TaggableModel.tagged_with("a, e", context: %i[skills needs], wild: true, any: true).map(&:id).sort).
            to eq [taggable_one.id, taggable_two.id].sort
      end

      it "exclude" do
        expect(TaggableModel.tagged_with("b, c", context: %i[needs offerings], wild: true, exclude: true).map(&:id).sort).to eq [taggable_one.id].sort
        expect(TaggableModel.tagged_with("d, f", context: %i[skills offerings], wild: true, exclude: true).map(&:id).sort).
            to eq [taggable_two.id].sort
      end
    end

    describe ":parse" do
      it "uses the default parser to parse strings by default" do
        taggable_one = TaggableModel.create!(name: "a", skill_list: "a, \"b, c\", 'd, e'")

        expect(TaggableModel.tagged_with("z, a", any: true).to_a).to eq [taggable_one]
        expect(TaggableModel.tagged_with("z, \"b, c\"", any: true).to_a).to eq [taggable_one]
        expect(TaggableModel.tagged_with("z, 'd, e'", any: true).to_a).to eq [taggable_one]
      end

      it "doesn't parse if you tell it not to" do
        taggable_one = TaggableModel.create!(name: "a", skill_list: ["a, \"b, c\", 'd, e'", { parse: false }])

        expect(TaggableModel.tagged_with("a, \"b, c\", 'd, e'", parse: false).to_a).to eq [taggable_one]
      end
    end

    describe ":parser" do
      it "uses the passed in parser" do
        taggable_one = TaggableModel.create!(name: "a", skill_list: ["a, \"b, c\", 'd, e'", { parser: ActsAsTaggableOnMongoid::GenericParser }])

        expect(TaggableModel.tagged_with("a, \"b, e'", parser: ActsAsTaggableOnMongoid::GenericParser).to_a).to eq [taggable_one]
      end
    end

    describe "list adjustments" do
      it "converts lowercase" do
        taggable = DifferentTagged.create! name: "a", case_list: "MiXeD CaSe, someTHING"

        expect(DifferentTagged.tagged_with("SOMEthing, Mixed Case", on: :cases, all: true)).to eq [taggable]
      end

      it "parameterizes" do
        taggable = DifferentTagged.create! name: "a", param_list: "MiXeD-CaSe, some-THING"

        expect(DifferentTagged.tagged_with("some THING, MiXeD CaSe", on: :params, all: true)).to eq [taggable]
      end

      it "parser" do
        taggable = DifferentTagged.create! name: "a", custom_parser_list: ["'a, list', \"b, list\""]

        expect(DifferentTagged.tagged_with("\"b, list\", list', 'a", on: :custom_parsers, all: true)).to eq [taggable]
      end
    end
  end
end
