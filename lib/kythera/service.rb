#
# kythera: services for IRC networks
# lib/kythera/service.rb: Service class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is the base class for a service. All services modules must subclass this.
# For the full documentation see `doc/extensions.md`
#
class Service
    # A list of all services classes
    @@services_classes = []

    # A list of all instantiated services
    @@services = []

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
    #
    def self.instantiate(uplink)
        @@services_classes.each do |srv|
            next unless srv.verify_configuration

            s = srv.new(uplink)
            @@services << s
        end
    end

    # This should never be called except from a subclass, and only exists
    # as a guide for arguments.
    def initialize(uplink)
        @uplink = uplink
    end

    private

    # You must override this or your service doesn't do too much huh?
    def irc_privmsg(user, params)
        $log.debug "I'm a Service that didn't override irc_privmsg!"
    end
end
