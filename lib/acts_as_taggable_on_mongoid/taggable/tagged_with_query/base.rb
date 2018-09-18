# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Taggable
    class TaggedWithQuery
      # A base class with shared code for match queries.
      class Base
        attr_reader :taggable_model,
                    :tag_definition,
                    :tag_list,
                    :options

        def initialize(tag_definition, tag_list, options)
          @tag_definition = tag_definition
          @tag_list       = tag_list
          @options        = options
        end

        private

        # Any is relatively simple, but All and exclude are a bit more complicated.  To make the code simpler
        # I'm treating all of them the same.
        # We build an aggregation of all of the matching taggables whose key_name is in the list of tags with the
        # count of the matching key names.  We then filter on that count.
        #
        # * All - count == tag_list count
        # * Any - count > 0
        # * Exclude - count > 0 (but anything that isn't in that count)
        def build_ids_from(count_selector)
          where_query = tagging_query.where(:tag_name.in => tag_list)
          build_ids_from_query(where_query, count_selector)
        end

        def build_tagless_ids_from(count_selector)
          build_ids_from_query(tagging_query, count_selector)
        end

        def build_ids_from_query(where_query, count_selector)
          pipeline = where_query.
              group(_id: { taggable_id: "$taggable_id", tag_name: "$tag_name" }).
              group(_id: "$_id.taggable_id", :count.sum => 1).
              pipeline.
              concat(count_selector.to_pipeline)

          tag_definition.taggings_table.collection.aggregate(pipeline).to_a.map { |counts| counts[:_id] }
        end

        def tagging_query
          context       = options[:on]
          tagging_query = tag_definition.taggings_table.where(taggable_type: tag_definition.owner.name)
          tagging_query = tagging_query.where(:context.in => context) if context.present?

          time_constraints tagging_query
        end

        def time_constraints(tagging_query)
          start_at      = options[:start_at]
          end_at        = options[:end_at]

          tagging_query = tagging_query.where(:created_at.gte => start_at) if start_at.present?
          tagging_query = tagging_query.where(:created_at.lt => end_at) if end_at.present?

          tagging_query
        end
      end
    end
  end
end
