# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TaggedWithQuery
      # A class finding all Taggable objects which include all of the passed in tags (may include other tags as well).
      class AllTagsQuery < ActsAsTaggableOnMongoid::Taggable::TaggedWithQuery::Base
        def build
          { :id.in => included_ids }
        end

        def included_ids
          selector         = Origin::Selector.new
          selector[:count] = tag_list.count

          build_ids_from(selector)
        end
      end
    end
  end
end
