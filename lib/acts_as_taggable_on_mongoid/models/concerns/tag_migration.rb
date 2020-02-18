# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # A module that defines methods to migrate a Tag model.
      #
      # Include the module on your Tag class and call `atom_migrate_up` to migrate from 0.x to 1.x versions
      # of the model.
      #
      # Migrations:
      #   * tagger was added to the model and indexes.
      #     Drop the old indexes and create the new ones.
      module TagMigration
        extend ActiveSupport::Concern

        class_methods do
          def atom_migrate_up
            collection.indexes.drop_one "name_1_taggable_type_1_context_1" if collection.indexes.get "name_1_taggable_type_1_context_1"

            create_indexes
          end
        end
      end
    end
  end
end
