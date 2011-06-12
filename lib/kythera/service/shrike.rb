#
# kythera: services for TSora IRC networks
# lib/kythera/service/shrike.rb: implements shrike's X
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

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

    attr_reader :config, :user

    # Is this service enabled in the configuration?
    def self.disabled?
        not $config.shrike
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

        # Introduce our client to the network
        @user = @uplink.introduce_user(@config.nickname, @config.username,
                                       @config.hostname, @config.realname)
    end

    public

    def irc_privmsg(user, params)
        log.debug "shrike got PRIVMSG but I'm lazy for now: #{params.inspect}"
    end
end

# This has to be at the end because this file needs to see the class above
require 'kythera/service/shrike/configuration'
