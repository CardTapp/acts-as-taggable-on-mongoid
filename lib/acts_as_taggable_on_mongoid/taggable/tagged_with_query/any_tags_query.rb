# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TaggedWithQuery
      # A class finding all Taggable objects which include any of the passed in tags.
      class AnyTagsQuery < ActsAsTaggableOnMongoid::Taggable::TaggedWithQuery::Base
        def build
          { :id.in => included_ids }
        end

        def included_ids
          selector         = Origin::Selector.new
          selector[:count] = { "$gt" => 0 }

          build_ids_from(selector)
        end
      end
    end
  end
end
