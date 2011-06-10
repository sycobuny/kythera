#
# kythera: services for TSora IRC networks
# lib/kythera/server.rb: Server class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This is just a base class. All protocol module should monkeypatch this.
class Server
    include Loggable

    # A list of all servers. The protocol module should decide what the key is.
    @@servers = {}

    # Attribute reader for `@@servers`
    #
    # @return [Hash] a list of all Servers
    #
    def self.servers
        @@servers
    end

    # The server's name
    attr_accessor :name

    # The server's description
    attr_accessor :description

    # The Users on this server
    attr_reader :users

    # Creates a new server. Should be patched by the protocol module.
    def initialize(logger)
        @logger     = nil
        @users      = []
        self.logger = logger
    end

    public

    # Adds a User as a member
    #
    # @param [User] user the User to add
    #
    def add_user(user)
        @users << user
        log.debug "user joined #{@name}: #{user.nickname}"
    end

    # Deletes a User as a member
    #
    # @param [User] user User object to delete
    #
    def delete_user(user)
        @users.delete(user)
        log.debug "user left #{@name}: #{user.nickname} (#{@users.length})"
    end
end
