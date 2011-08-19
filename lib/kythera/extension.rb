#
# kythera: services for IRC networks
# lib/kythera/extension.rb: extensions interface
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is the base class for an extension. All extensions must subclass this.
# For the full documentation see `doc/extensions.md`
#
class Extension
    # A list of all extension classes
    @@extension_classes = []

    # Detect when we are subclassed
    #
    # @param [Class] klass the class that subclasses us
    #
    def self.inherited(klass)
        @@extension_classes << klass
    end

    # Verify loaded extensions work with our version
    def self.verify_and_load
        # Remove the incompatible ones
        @@extension_classes.delete_if do |klass|
            kyver = Gem::Requirement.new(klass::KYTHERA_VERSION)

            unless kyver.satisfied_by?(Gem::Version.new(Kythera::VERSION))
                if $config.me.unsafe_extensions == :ignore
                    false
                    next
                else
                    puts "kythera: incompatable extension '#{klass::NAME}'"
                    puts "kythera: needs kythera version '#{kyver}'"
                end


                abort if $config.me.unsafe_extensions == :die

                true
            end
        end

        # Go ahead and load the ones that passed verification
        @@extension_classes.each do |klass|
            require "ext/#{klass::NAME}/#{klass::NAME}.rb"
        end
    end
end
