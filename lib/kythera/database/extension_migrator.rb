#
# kythera: services for IRC networks
# lib/kythera/extension_migrator.rb: custom migrations for extensions
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Stephen Belcher <sycobuny@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This file should only be included by rake when running migrations.
#

module Sequel
    # add a name, kythera_schema_min and kythera_schema_max command to the DSL
    class MigrationDSL
        def name(name)
            migration.name = name
        end

        def kythera_schema_min(min)
            migration.kythera_schema_min = min
        end

        def kythera_schema_max(max)
            migration.kythera_schema_max = max
        end
    end

    # add fields to SimpleMigrator to allow the previous calls to work
    class SimpleMigrator
        attr_accessor :name, :kythera_schema_min, :kythera_schema_max
    end

    class Migrator
        class << self
            alias :old_migrator_class :migrator_class

            def migrator_class(directory)
                if directory =~ m{/extensions/}
                    ExtensionsMigrator
                else
                    old_migrator_class(directory)
                end
            end
        end

        private_class_method :old_migrator_class
        private_class_method :migrator_class
    end

    class ExtensionMigrator < IntegerMigrator
        DEFAULT_SCHEMA_TABLE = :schema_info

        def initialize
            super

            @version_to_migration_lookup = {}
            version_numbers.zip(migrations).each do |v, m|
                @version_to_migration_lookup[v] = m
            end
        end

        def set_migration_version(version)
            migration = @version_to_migration_lookup[version]

            extension = migration.name
            ds        = db.from(table)
            ds_update = ds.where(:name => extension)

            args = {
                :name                => extension,
                :version             => version,
                :min_kythera_version => migration.min_kythera_version,
                :max_kythera_version => migration.max_kythera_version
            }

            ds.empty? ? ds.insert(args) : ds_update.update(args)
        end
    end
end
