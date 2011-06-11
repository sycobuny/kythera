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

    # The user's Server object
    attr_reader :server

    # The user's nickname
    attr_reader :nickname

    # The user's username
    attr_reader :username

    # The user's hostname
    attr_reader :hostname

    # The user's gecos/realname
    attr_reader :realname

    # A Hash keyed by Channel of the user's status modes
    attr_reader :status_modes

    # Creates a new user. Should be patched by the protocol module.
    def initialize(server, nick, user, host, real, logger)
        @server   = server
        @nickname = nick
        @username = user
        @hostname = host
        @realname = real
        @logger   = nil

        @status_modes = {}
        self.logger   = logger

        @@users[nick] = self
    end

    public

    # Adds a status mode for this user on a particular channel
    #
    # @param [Channel] channel the Channel object we have the mode on
    # @param [Symbol] mode a Symbol representing the mode flag
    #
    def add_status_mode(channel, mode)
        (@status_modes[channel] ||= []) << mode

        log.debug "status mode added: #{@nickname}/#{channel} -> #{mode}"
    end

    # Deletes a status mode for this user on a particular channel
    #
    # @param [Channel] channel the Channel object we have lost the mode on
    # @param [Symbol] mode a Symbol representing the mode flag
    #
    def delete_status_mode(channel, mode)
        unless @status_modes[channel]
            log.warn "cannot remove mode from a channel with no known modes"
            log.warn "#{channel} -> #{mode}"

            return
        end

        @status_modes[channel].delete(mode)

        log.debug "status mode deleted: #{@nickname}/#{channel} -> #{mode}"
    end

    # Deletes all status modes for given channel
    #
    # @param [Channel] channel the Channel object to clear modes for
    #
    def clear_status_modes(channel)
        unless @status_modes[channel]
            log.warn "cannot clear modes from a channel with no known modes"
            log.warn "#{channel} -> clear all modes"

            return
        end

        @status_modes[channel] = []
    end
end
