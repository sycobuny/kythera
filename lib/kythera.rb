#
# kythera: services for TSora IRC networks
# lib/kythera.rb: configuration DSL implementation
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# Require all of our files here and only here
require 'kythera/run'

# Starts the parsing of the configuraiton DSL
#
# @param [Proc] block contains the actual configuration code
def configure &block
    Kythera.config = Object.new

    class << Kythera.config
        # Adds methods to the parser from an arbitrary module
        #
        # @param [Module] mod the module containing methods to add
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

# Contains all of the application-wide stuff
module Kythera
    # For backwards-incompatible changes
    V_MAJOR = 0

    # For backwards-compatible changes
    V_MINOR = 0

    # For minor changes and bugfixes
    V_PATCH = 1

    # A String representation of the version number
    VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"

    # Our name for things we print out
    ME = 'kythera'

    # Application-wide configuraiton settings
    @@config = nil

    # Configuration reader
    #
    # @return [Object] the configuration settings
    def self.config
        @@config
    end

    # Configuration writer
    #
    # @param [Object] config a plain Object for the configuration
    # @return [Object] the new configuration settings
    def self.config= config
        @@config = config
    end

    # Verifies that the configuration isn't invalid or incomplete
    def self.verify_configuration
        puts "#{ME}: XXX - configuration verification!"
    end
end

# Contains the methods that actually implement the configuration
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
