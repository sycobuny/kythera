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
    # @return [Hash] a list of all Servers
    #
    def self.users
        @@users
    end

    # Instance attributes
    attr_reader :nickname, :username, :hostname, :realname

    # Creates a new server. Should be patched by the protocol module.
    def initialize(nick, user, host, real, logger)
        @nickname = nick
        @username = user
        @hostname = host
        @realname = real

        @logger = logger

        @@users[nick] = self
    end
end
