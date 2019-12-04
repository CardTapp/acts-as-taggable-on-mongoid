# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TaggedWithQuery
      # A class finding all Taggable objects which exclude all of the passed in tags.
      class ExcludeTagsQuery < ActsAsTaggableOnMongoid::Taggable::TaggedWithQuery::Base
        def build
          { :id.in => included_ids }
        end

        def included_ids
          selector         = Mongoid::Criteria::Queryable::Selector.new
          selector[:count] = { "$gt" => 0 }

          ids = build_ids_from(selector)
          build_tagless_ids_from(selector) - ids
        end
      end
    end
  end
end
