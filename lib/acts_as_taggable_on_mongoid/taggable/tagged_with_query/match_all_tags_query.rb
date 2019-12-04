# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TaggedWithQuery
      # A class finding all Taggable objects which include all and only all of the passed in tags.
      class MatchAllTagsQuery < ActsAsTaggableOnMongoid::Taggable::TaggedWithQuery::Base
        def build
          { :id.in => included_ids }
        end

        def included_ids
          selector         = Mongoid::Criteria::Queryable::Selector.new
          selector[:count] = { "$ne" => tag_list.count }

          AllTagsQuery.new(tag_definition, tag_list, options).included_ids -
              build_tagless_ids_from(selector)
        end
      end
    end
  end
end
