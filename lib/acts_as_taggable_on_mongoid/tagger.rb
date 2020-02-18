# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  # This module defines the class methods to be added to the Mongoid model so that
  # tags can be defined on and added to a model.
  #
  # When a tag is added to a model, additional modules will be included to add methods that
  # are needed only if a tag is actually being used.
  module Tagger
    extend ActiveSupport::Concern

    class_methods do
      # Options include:
      #   * tags_table
      #     The class to use for Tags
      #   * taggings_table
      #     The class to use for Taggings

      # Make a model a tagger.  This allows a model to claim ownership of taggings and their tags.
      #
      # Example:
      #   class User
      #     acts_as_tagger
      #   end
      def acts_as_tagger(options = {})
        options = options.with_indifferent_access

        add_taggings_tagger_relation(options)
        add_tags_owner_relation(options)

        include ActsAsTaggableOnMongoid::Tagger::TagMethods
      end

      private

      def add_tags_owner_relation(options)
        tags_table = options[:tags_table] || ActsAsTaggableOnMongoid.tags_table
        tags_name  = "owned_#{tags_table.name.demodulize.underscore.downcase.pluralize.to_sym}"

        return if relations[tags_name.to_s]

        has_many tags_name,
                 as:         :owner,
                 dependent:  :destroy,
                 class_name: tags_table.name
      end

      def add_taggings_tagger_relation(options)
        taggings_table = options[:taggings_table] || ActsAsTaggableOnMongoid.taggings_table
        taggings_name  = "owned_#{taggings_table.name.demodulize.underscore.downcase.pluralize.to_sym}"

        return if relations[taggings_name.to_s]

        has_many taggings_name,
                 as:         :tagger,
                 dependent:  :destroy,
                 class_name: taggings_table.name
      end
    end
  end
end
