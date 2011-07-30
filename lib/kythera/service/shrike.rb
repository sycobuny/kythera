#
# kythera: services for IRC networks
# lib/kythera/service/shrike.rb: implements shrike's X
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

require 'kythera/service/shrike/commands'
require 'kythera/service/shrike/configuration'

# This service is designed to implement the functionality of Shrike IRC Services
class Shrike < Service
    # For backwards-incompatible changes
    V_MAJOR = 0

    # For backwards-compatible changes
    V_MINOR = 0

    # For minor changes and bugfixes
    V_PATCH = 1

    # A String representation of the version number
    VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"

    # Our User object is visible for the Service API
    attr_reader :user

    # Is this service enabled in the configuration?
    #
    # @return [Boolean] true or false
    #
    def self.enabled?
        if $config.respond_to?(:shrike) and $config.shrike
            true
        else
            false
        end
    end

    # Verify our configuration
    #
    # @return [Boolean] true or false
    #
    def self.verify_configuration
        c = $config.shrike

        unless c.nickname and c.username and c.hostname and c.realname
            false
        else
            true
        end
    end

    # This is all we do for now :)
    #
    # @param [Uplink] uplink the interface to the IRC server
    # @param [Logger] logger our logger object
    #
    def initialize(uplink, logger)
        # Prepare the logger and uplink
        super

        @config = $config.shrike

        log.info "shrike module loaded (version #{VERSION})"

        # Join our configuration channel
        $eventq.handle(:end_of_burst) do
            # Introduce our client to the network
            @user = @uplink.introduce_user(@config.nickname, @config.username,
                                           @config.hostname, @config.realname,
                                           'o')

            @uplink.join(@user, @config.channel) if @config.channel
        end
    end

    public

    def irc_privmsg(user, params)
        cmd = params.delete_at(0)
        meth = "do_#{cmd}".downcase.to_sym

        if self.respond_to?(meth, true)
            self.send(meth, user, params)
        else
            @uplink.notice(@user, user, "Invalid command: \2#{cmd}\2")
        end
    end
end
