#
# kythera: services for TSora IRC networks
# lib/kythera/user.rb: User class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This is just a base class. All protocol module should monkeypatch this.
class User
    include Loggable

    # A list of all users. The protocol module should decide what the key is.
    @@users = {}

    # Attribute reader for `@@users`
    #
    # @return [Hash] a list of all Users
    #
    def self.users
        @@users
    end

    # Instance attributes
    attr_reader :nickname, :username, :hostname, :realname, :cmodes

    # Creates a new user. Should be patched by the protocol module.
    def initialize(nick, user, host, real, logger)
        @nickname = nick
        @username = user
        @hostname = host
        @realname = real
        @logger   = nil

        @cmodes = {}

        self.logger = logger

        @@users[nick] = self
    end

    public

    # Adds a status mode for this user on a particular channel
    #
    # @param [Channel] channel the Channel object we have the mode on
    # @param [Symbol] mode a Symbol representing the mode flag
    #
    def add_status_mode(channel, mode)
        (@cmodes[channel] ||= []) << mode

        log.debug "status mode added: #{@nickname}/#{channel} -> #{mode}"
    end

    # Deletes a status mode for this user on a particular channel
    #
    # @param [Channel] channel the Channel object we have lost the mode on
    # @param [Symbol] mode a Symbol representing the mode flag
    #
    def delete_status_mode(channel, mode)
        unless @cmodes[channel]
            log.warning "cannot remove mode from a channel with no known modes"
            log.warning "#{channel} -> #{mode}"

            return
        end

        @cmodes[channel].delete mode

        log.debug "status mode deleted: #{@nickname}/#{channel} -> #{mode}"
    end

    # Deletes all status modes for given channel
    #
    # @param [Channel] channel the Channel object to clear modes for
    #
    def clear_status_modes(channel)
        unless @cmodes[channel]
            log.warning "cannot clear modes from a channel with no known modes"
            log.warning "#{channel} -> clear all modes"

            return
        end

        @cmodes[channel] = []
    end
end
