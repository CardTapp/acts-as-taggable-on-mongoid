# frozen_string_literal: true

module ActsAsTaggableOnMongoid
  module Models
    module Concerns
      # A module that defines methods to migrate a Tag model.
      #
      # Mongoid does not have a standardized migration scheme, but migrations of one kind or another
      # are often a fact of life, and are in this situation because of the need to change an existing
      # index.
      #
      # Using whatever migration methodology you prefer, you need to run the appropriate migration method
      # or methods on the Tag module used by your project.
      #
      # The migrations are named for the ActsAsTaggableMongoid versions upon which they need to be run.
      # Run the correct migration(s) for the version of ActsAsTaggableOnMongoid you are currently using
      # This module does not and cannot verify the version you are migrating from nor if the migration
      # has been run before.  Doing so is assumed to be the responsibility of your chosen
      # Migration methodology.
      #
      # Example:
      #
      # # When a migration is needed, the method "up" is called:
      # def up
      #   TaggingModel.include ActsAsTaggableOnMongoid::Models::Concerns::TaggingMigration
      #   TaggingModel.atom_migrate_up_6_0_1_to_6_1_1
      # end
      #
      # The migration methods should only be run once if possible, but every reasonable effort is made to
      # ensure that the migration methods are safe to re-run.
      module TaggingMigration
        extend ActiveSupport::Concern

        class_methods do
          # :reek:UncommunicativeMethodName - The name indicates what gem versions the migration is from/to
          def atom_migrate_up_6_0_1_to_6_1_1
            indexes = collection.indexes
            indexes.drop_one "tagging_taggable_context_tag_name" if indexes.get "tagging_taggable_context_tag_name"

            create_indexes
          end
        end
      end
    end
  end
end
