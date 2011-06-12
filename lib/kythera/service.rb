#
# kythera: services for TSora IRC networks
# lib/kythera/service.rb: Service class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is the base class for a service. All services modules must subclass this.
# For the full documentation see `doc/SERVICES.md`
#
class Service
    include Loggable

    # A list of all services classes
    @@services_classes = []

    # A list of all instantiated services (keyed by nickname)
    @@services = {}

    # Attribute reader for `@@services`
    #
    # @return [Array] a list of all services
    #
    def self.services
        @@services
    end

    # Detect when we are subclassed
    #
    # @param [Class] klass the class that subclasses us
    #
    def self.inherited(klass)
        @@services_classes << klass
    end

    # Instantiate all of our services
    #
    # @param [Uplink] uplink the Uplink to pass to the services
    # @param [Logger] logger the logger to pass to the services
    #
    def self.instantiate(uplink, logger)
        @@services_classes.each do |srv|
            next if srv.disabled?

            s = srv.new(uplink, logger)
            @@services[s.config.nickname] = s
        end
    end

    # This should never be called except from a subclass, and only exists
    # as a guide for arguments.
    def initialize(uplink, logger)
        @uplink = uplink
        @logger = nil

        self.logger = logger
    end

    # You must override this or your service doesn't do too much huh?
    def irc_privmsg(user, params)
        log.debug "I'm a Service that didn't override irc_privmsg!"
    end
end
