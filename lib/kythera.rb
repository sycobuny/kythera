#
# kythera: services for TSora IRC networks
# lib/kythera.rb: configuration DSL implementation
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# XXX - Require all of our files here and only here

# Starts the parsing of the configuraiton DSL
#
# @block [Proc] contains the actual configuration code
def configure &block
    Kythera.config = Object.new

    class << Kythera.config
        # Adds methods to the parser from an arbitrary module
        #
        # @mod [Module] the module containing methods to add
        def use mod
            Kythera.config.extend mod
        end
    end

    # The configuration magic begins here...
    Kythera.config.instance_eval &block

    # Make sure the configuration information is valid
    Kythera.verify_configuration

    # Configuration is solid, now let's actually start up
    Kythera.run
end

module Kythera
    #
    # Define version information in accordance with semantic versioning.
    # http://semver.org/
    #
    V_MAJOR = 0
    V_MINOR = 0
    V_PATCH = 1

    # A String representation of the version number
    VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"

    # Application-wide configuraiton settings
    @@config = nil

    # Configuration accessors
    def self.config; @@config; end
    def self.config=(config); @@config = config; end

    # Verify that the configuration isn't invalid or incomplete
    def self.verify_configuration
        puts "XXX - configuration verification!"
    end

    def self.run
        puts "kythera: version #{VERSION} [#{RUBY_PLATFORM}]"
        puts "kythera: configuration parsed."
        puts "kythera: i don't do anything else yet, but bravo, brave one."
    end
end

module Kythera::Configuration
    # Parses the `daemon` section of the configuration
    def daemon
    end

    # Parses the `uplink` section of the configuration
    def uplink name
    end

    # Parses the `userserv` section of the configuration
    def userserv
    end
end
