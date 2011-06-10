#
# kythera: services for TSora IRC networks
# lib/kythera/service.rb: Service class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This is the base class for a service. All services modules must subclass this.
class Service
    include Loggable

    # A list of all services
    @@services = []

    # Attribute reader for `@@services`
    #
    # @return [Hash] a list of all services
    #
    def self.services
        @@services
    end

    # Detect when we are subclassed
    #
    # @param [Class] klass the class that subclasses us
    #
    def self.inherited(klass)
        @@services << klass
    end

    # This should never be called except from a subclass, and only exists
    # as a guide for arguments.
    def initialize(logger)
        @logger = nil

        self.logger = logger

        # Set up your events here, like:
        # $eventq.handle(:irc_privmsg) { my_privmsg_parser }
    end
end
